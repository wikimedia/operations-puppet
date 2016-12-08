# role/eventlogging.pp
#
# TODO: Move these into role module as
# role::eventlogging::analytics::* classes
#
# These role classes configure various eventlogging services for
# processing analytics EventLogging data.
# The setup is described in detail on
# <https://wikitech.wikimedia.org/wiki/EventLogging>. End-user
# documentation is available in the form of a guide, located at
# <https://www.mediawiki.org/wiki/Extension:EventLogging/Guide>.
#
# There exist two APIs for generating events: efLogServerSideEvent() in
# PHP and mw.eventLog.logEvent() in JavaScript. Events are URL-encoded
# and sent to our servers by means of an HTTP/S request to varnish,
# where a varnishkafka instance forwards to Kafka.  These event streams are
# parsed, validated, and multiplexed into an output streams in Kafka.


# == Class role::eventlogging
# Parent class for eventlogging service role classes.
# This just installs eventlogging and sets up some configuration variables.
#
class role::eventlogging {
    system::role { 'role::eventlogging':
        description => 'EventLogging',
    }

    # EventLogging for analytics processing is deployed
    # as the eventlogging/analytics scap target.
    # eventlogging::deployment::target { 'analytics': }
    # class { 'eventlogging::server':
        # eventlogging_path => '/srv/deployment/eventlogging/analytics'
    # }

    # Get the Kafka configuration
    $kafka_config         = kafka_config('analytics')
    $kafka_brokers_string = $kafka_config['brokers']['string']

    # Where possible, if this is set, it will be included in client configuration
    # to avoid having to do API version for Kafka < 0.10 (where there is not a version API).
    $kafka_api_version = $kafka_config['api_version']

    # Using kafka-confluent as a consumer is not currently supported by this puppet module,
    # but is implemented in eventlogging.  Hardcode the scheme for consumers for now.
    $kafka_consumer_scheme = 'kafka://'

    # Commonly used Kafka input URIs.
    $kafka_mixed_uri = "${kafka_consumer_scheme}/${kafka_brokers_string}?topic=eventlogging-valid-mixed"
    $kafka_client_side_raw_uri = "${kafka_consumer_scheme}/${kafka_brokers_string}?topic=eventlogging-client-side"

    # # This check was written for eventlog1001, so only include it there.,
    # if $::hostname == 'eventlog1001' {
    #
    #     # Alert when / gets low. (eventlog1001 has a 9.1G /)
    #     nrpe::monitor_service { 'eventlogging_root_disk_space':
    #         description   => 'Eventlogging / disk space',
    #         nrpe_command  => '/usr/lib/nagios/plugins/check_disk -w 1024M -c 512M -p /',
    #         contact_group => 'analytics',
    #     }
    #
    #     # Alert when /srv gets low. (eventlog1001 has a 456G /srv)
    #     # Currently, /srv/log/eventlogging grows at about 500kB / s.
    #     # Which is almost 2G / hour.  100G gives us about 2 days to respond,
    #     # 50G gives us about 1 day.  Logrotate should keep enough disk space free.
    #     nrpe::monitor_service { 'eventlogging_srv_disk_space':
    #         description   => 'Eventlogging /srv disk space',
    #         nrpe_command  => '/usr/lib/nagios/plugins/check_disk -w 100000M -c 50000M -p /srv',
    #         contact_group => 'analytics',
    #     }
    # }
    #
    # # make sure any defined eventlogging services are running
    # class { '::eventlogging::monitoring::jobs': }
}


#
# ==== Data flow classes ====
#


# == Class role::eventlogging::forwarder
# This class was responsible for forwarding incoming raw events from UDP
# into the eventlogging system - this behavior has been deprecated and
# server side events are directly sent from Mediawiki via HTTP POST to the
# event beacon endpoint and will be processed as client side events.
#
# This forwarder class exists only for backwards compatibility for services
# consuming from the legacy ZMQ stream now.
class role::eventlogging::forwarder inherits role::eventlogging {
    $eventlogging_host    = hiera('eventlogging_host', $::ipaddress)

    # This forwards the kafka eventlogging-valid-mixed topic to
    # ZMQ port 8600 for backwards compatibility.
    eventlogging::service::forwarder { 'legacy-zmq':
        input   => "${kafka_mixed_uri}&enable_auto_commit=False&identity=eventlogging_legacy_zmq",
        outputs => ["tcp://${eventlogging_host}:8600"],
    }

    ferm::service { 'eventlogging-zmq-legacy-stream':
        proto   => 'tcp',
        notrack => true,
        port    => '8600',
        srange  => '@resolve((hafnium.eqiad.wmnet graphite1001.eqiad.wmnet))',
    }
}


# == Class role::eventlogging::processor
# Reads raw events, parses and validates them, and then sends
# them along for further consumption.
#
class role::eventlogging::processor inherits role::eventlogging {
    $kafka_consumer_group = hiera(
        'eventlogging_processor_kafka_consumer_group',
        'eventlogging_processor_client_side_00'
    )

    # Run N parallel client side processors.
    # These will auto balance amongst themselves.
    $client_side_processors = hiera(
        'eventlogging_client_side_processors',
        ['client-side-00', 'client-side-01']
    )

    # Choose the eventlogging URI scheme to use for consumers and producer (inputs vs outputs).
    # This allows us to try out different Kafka handlers and different kafka clients
    # that eventlogging supports.  The default is kafka://.  Also available is kafka-confluent://
    # eventlogging::processor is the only configured analytics eventlogging kafka producer, so we
    # only need to define this here.
    $kafka_producer_scheme = hiera('eventlogging_kafka_producer_scheme', 'kafka://')

    # Read in raw events from Kafka, process them, and send them to
    # the schema corresponding to their topic in Kafka.
    $kafka_schema_output_uri  = "${kafka_producer_scheme}/${kafka_brokers_string}?topic=eventlogging_{schema}"

    # The downstream eventlogging MySQL consumer expects schemas to be
    # all mixed up in a single stream.  We send processed events to a
    # 'mixed' kafka topic in order to keep supporting it for now.
    # We blacklist certain high volume schemas from going into this topic.
    $mixed_schema_blacklist = hiera('eventlogging_valid_mixed_schema_blacklist', undef)
    $kafka_mixed_output_uri = $mixed_schema_blacklist ? {
        undef   => "${kafka_producer_scheme}/${kafka_brokers_string}?topic=eventlogging-valid-mixed",
        default => "${kafka_producer_scheme}/${kafka_brokers_string}?topic=eventlogging-valid-mixed&blacklist=${mixed_schema_blacklist}"
    }

    # Append this to query params of kafka-python writer if set.
    # kafka-confluent defaults to setting this to 0.9 anyway.
    $kafka_api_version_param = $kafka_api_version ? {
        undef   => '',
        default => "&api_version=${kafka_api_version}"
    }

    # Increase number and backoff time of retries for async
    # analytics uses.  If metadata changes, we should give
    # more time to retry. NOTE: testing this in production
    # STILL yielded some dropped messages.  Need to figure
    # out why and stop it.  This either needs to be higher,
    # or it is a bug in kafka-python.
    # See: https://phabricator.wikimedia.org/T142430
    $kafka_producer_args = $kafka_producer_scheme ? {
        # args for kafka-confluent handler writer
        'kafka-confluent://' => 'message.send.max.retries=6,retry.backoff.ms=200',
        # args for kafka-python handler writer
        'kafka://'           => "retries=6&retry_backoff_ms=200${kafka_api_version_param}"
    }

    eventlogging::service::processor { $client_side_processors:
        format         => '%q %{recvFrom}s %{seqId}d %t %o %{userAgent}i',
        input          => "${kafka_client_side_raw_uri}${kafka_api_version_param}",
        sid            => $kafka_consumer_group,
        outputs        => [
            "${kafka_schema_output_uri}&${kafka_producer_args}",
            "${kafka_mixed_output_uri}&${kafka_producer_args}",
        ],
        output_invalid => true,
    }
}


# == Class role::eventlogging::consumer::mysql
# Consumes the stream of events and writes them to MySQL
#
class role::eventlogging::consumer::mysql inherits role::eventlogging {
    ## MySQL / MariaDB

    # Log strictly valid events to the 'log' database on m4-master.

    class { 'passwords::mysql::eventlogging': }    # T82265
    $mysql_user = $passwords::mysql::eventlogging::user
    $mysql_pass = $passwords::mysql::eventlogging::password
    $mysql_db = $::realm ? {
        production => 'm4-master.eqiad.wmnet/log',
        labs       => '127.0.0.1/log',
    }

    # Run N parallel mysql consumers processors.
    # These will auto balance amongst themselves.
    $mysql_consumers = hiera(
        'eventlogging_mysql_consumers',
        ['mysql-m4-master-00']
    )
    $kafka_consumer_group = 'eventlogging_consumer_mysql_00'

    # Append this to query params if set.
    $kafka_api_version_param = $kafka_api_version ? {
        undef   => '',
        default => "&api_version=${kafka_api_version}"
    }

    # Define statsd host url to send mysql insert metrics.
    # For beta cluster, set in https://wikitech.wikimedia.org/wiki/Hiera:Deployment-prep
    $statsd_host          = hiera('eventlogging_statsd_host',      'statsd.eqiad.wmnet')

    # Kafka consumer group for this consumer is mysql-m4-master
    eventlogging::service::consumer { $mysql_consumers:
        # auto commit offsets to kafka more often for mysql consumer
        input  => "${kafka_mixed_uri}&auto_commit_interval_ms=1000${$kafka_api_version_param}",
        output => "mysql://${mysql_user}:${mysql_pass}@${mysql_db}?charset=utf8&statsd_host=${statsd_host}&replace=True",
        sid    => $kafka_consumer_group,
        # Restrict permissions on this config file since it contains a password.
        owner  => 'root',
        group  => 'eventlogging',
        mode   => '0640',
    }
}


# == Class role::eventlogging::consumer::files
# Consumes streams of events and writes them to log files.
#
class role::eventlogging::consumer::files inherits role::eventlogging {
    # Log all raw log records and decoded events to flat files in
    # $out_dir as a medium of last resort. These files are rotated
    # and rsynced to stat1003 & stat1002 for backup.

    $out_dir = '/srv/log/eventlogging'

    # We ensure the /srv/log (parent of $out_dir) manually here, as
    # there is no proper class to rely on for this, and starting a
    # separate would be an overkill for now.
    if !defined(File['/srv/log']) {
        file { '/srv/log':
            ensure => 'directory',
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
        }
    }

    # Logs are collected in <$log_dir> and rotated daily.
    file { [$out_dir, "${out_dir}/archive"]:
        ensure => 'directory',
        owner  => 'eventlogging',
        group  => 'eventlogging',
        mode   => '0664',
    }

    # TODO put this in a file when role::eventlogging
    # moves to role modules.
    $logrotate_content = "${out_dir}/*.log {
       daily
       olddir ${out_dir}/archive
       notifempty
       maxage 30
       rotate 1000
       dateext
       compress
       delaycompress
       missingok
}"

    logrotate::conf { 'eventlogging-files':
        ensure  => present,
        content => $logrotate_content,
        require => [
            File[$out_dir],
            File["${out_dir}/archive"]
        ],
    }

    $kafka_consumer_group = hiera(
        'eventlogging_files_kafka_consumer_group',
        'eventlogging_consumer_files_00'
    )

    # Append this to query params if set.
    $kafka_api_version_param = $kafka_api_version ? {
        undef   => '',
        default => "&api_version=${kafka_api_version}"
    }

    # Raw client side events:
    eventlogging::service::consumer { 'client-side-events.log':
        input  => "${kafka_client_side_raw_uri}&raw=True${kafka_api_version_param}",
        output => "file://${out_dir}/client-side-events.log",
        sid    => $kafka_consumer_group,
    }
    # Processed and valid all (AKA 'mixed') mixed.
    # Note that this does not include events that were
    # 'blacklisted' during processing.  Events are blacklisted
    # from these logs for volume reasons.
    eventlogging::service::consumer { 'all-events.log':
        input  =>  "${kafka_mixed_uri}${kafka_api_version_param}",
        output => "file://${out_dir}/all-events.log",
        sid    => $kafka_consumer_group,
    }

    $backup_destinations = $::realm ? {
        production => [  'stat1002.eqiad.wmnet', 'stat1003.eqiad.wmnet' ],
        labs       => false,
    }

    if ( $backup_destinations ) {
        class { 'rsync::server': }

        $rsync_clients_ferm = join($backup_destinations, ' ')
        ferm::service { 'eventlogging_rsyncd':
            proto  => 'tcp',
            port   => '873',
            srange => "@resolve((${rsync_clients_ferm}))",
        }

        rsync::server::module { 'eventlogging':
            path        => $out_dir,
            read_only   => 'yes',
            list        => 'yes',
            require     => File[$out_dir],
            hosts_allow => $backup_destinations,
        }
    }
}
