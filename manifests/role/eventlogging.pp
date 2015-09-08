# role/eventlogging.pp
#
# These role classes configure various eventlogging services.
# The setup is described in detail on
# <https://wikitech.wikimedia.org/wiki/EventLogging>. End-user
# documentation is available in the form of a guide, located at
# <https://www.mediawiki.org/wiki/Extension:EventLogging/Guide>.
#
# There exist two APIs for generating events: efLogServerSideEvent() in
# PHP and mw.eventLog.logEvent() in JavaScript. Events generated in PHP
# are sent by the app servers directly to eventlog* servers on UDP port 8421.
# JavaScript-generated events are URL-encoded and sent to our servers by
# means of an HTTP/S request to bits, which a varnishncsa instance
# forwards to eventlog* on port 8422. These event streams are parsed,
# validated, and multiplexed into an output stream that is published via
# ZeroMQ on TCP port 8600. Data sinks are implemented as subscribers
# that connect to this endpoint and read data into some storage medium.
#


# == Class role::eventlogging
# Parent class for eventlogging service role classes.
# This just installs eventlogging and sets up some configuration variables.
#
class role::eventlogging {
    system::role { 'role::eventlogging':
        description => 'EventLogging',
    }

    # Infer Kafka cluster configuration from this class
    class { 'role::analytics::kafka::config': }

    # Event data flows through several processes that communicate with each
    # other via TCP/IP sockets. By default, all processing is performed
    # on one node, but the work could be easily distributed across multiple hosts.

    # If all eventlogging services are on a single host, then you only need to
    # set this one hiera variable.  The following three will default to it.
    # NOTE:  ZeroMQ does not like using hostnames; use IP addresses.
    $eventlogging_host   = hiera('eventlogging_host', $::ipaddress)
    $forwarder_host      = hiera('eventlogging_forwarder_host',   $eventlogging_host)
    $processor_host      = hiera('eventlogging_processor_host',   $eventlogging_host)
    $multiplexer_host    = hiera('eventlogging_multiplexer_host', $eventlogging_host)

    # Define statsd host url
    # for beta cluster, set in https://wikitech.wikimedia.org/wiki/Hiera:Deployment-prep
    $statsd_host         = hiera('eventlogging_statsd_host',      'statsd.eqiad.wmnet')

    $kafka_brokers_array = $role::analytics::kafka::config::brokers_array
    $kafka_zookeeper_url = $role::analytics::kafka::config::zookeeper_url

    # By default, the EL Kafka writer writes events to
    # schema based topic names like eventlogging_SCHEMA,
    # with each message keyed by SCHEMA_REVISION.
    # If you want to write to a different topic, append topic=<TOPIC>
    # to your query params.
    $kafka_base_uri    = inline_template('kafka:///<%= @kafka_brokers_array.join(":9092,") + ":9092" %>')

    # Read in server side and client side raw events from
    # ZeroMQ, process them, and send events to schema
    # based topics in Kafka.
    $kafka_schema_uri  = "${kafka_base_uri}?topic=eventlogging_%(schema)s"
    # The downstream eventlogging MySQL consumer expects schemas to be
    # all mixed up in a single stream.  We send processed events to a
    # 'mixed' kafka topic in order to keep supporting it for now.
    $kafka_mixed_uri   = "${kafka_base_uri}?topic=eventlogging-valid-mixed"

    $kafka_server_side_raw_uri = "${kafka_base_uri}?topic=eventlogging-server-side"
    $kafka_client_side_raw_uri = "${kafka_base_uri}?topic=eventlogging-client-side"


    # jq is very useful, install it on eventlogging servers
    ensure_packages(['jq'])


    class { '::eventlogging': }


    if $::standard::has_ganglia {
        class { '::eventlogging::monitoring::ganglia': }
    }

    # This check was written for eventlog1001, so only include it there.,
    if $::hostname == 'eventlog1001' {

        # Alert when / gets low. (eventlog1001 has a 9.1G /)
        nrpe::monitor_service { 'eventlogging_root_disk_space':
            description   => 'Eventlogging / disk space',
            nrpe_command  => '/usr/lib/nagios/plugins/check_disk -w 1024M -c 512M -p /',
            contact_group => 'analytics',
        }

        # Alert when /srv gets low. (eventlog1001 has a 456G /srv)
        # Currently, /srv/log/eventlogging grows at about 500kB / s.
        # Which is almost 2G / hour.  100G gives us about 2 days to respond,
        # 50G gives us about 1 day.  Logrotate should keep enough disk space free.
        nrpe::monitor_service { 'eventlogging_srv_disk_space':
            description   => 'Eventlogging /srv disk space',
            nrpe_command  => '/usr/lib/nagios/plugins/check_disk -w 100000M -c 50000M -p /srv',
            contact_group => 'analytics',
        }
    }


    # analytics1010 is temporarily being used as a staging perf test
    # host for the EventLogging on Kafka project.  Disable job alerts there.
    $monitor_jobs_ensure = $::hostname ? {
        'analytics1010' => 'absent',
        default => 'present',
    }
    # make sure any defined eventlogging services are running
    class { '::eventlogging::monitoring::jobs':
        ensure => $monitor_jobs_ensure,
    }
}



#
# ==== Data flow classes ====
#


# == Class role::eventlogging::forwarder
# Responsible for forwarding incoming raw events from UDP
# into the eventlogging system.
#
class role::eventlogging::forwarder inherits role::eventlogging {
    # Server-side events are generated by MediaWiki and sent to eventlog*
    # on UDP port 8421, using wfErrorLog('...', 'udp://...'). eventlog*
    # is specified as the destination in $wgEventLoggingFile, declared
    # in wmf-config/CommonSettings.php.
    eventlogging::service::forwarder { 'server-side-raw':
        input   => 'udp://0.0.0.0:8421',
        outputs => ["tcp://${forwarder_host}:8421", $server_side_raw_uri],
        count   => true,
    }

    # Client-side events are generated by JavaScript-triggered HTTP/S
    # requests to //bits.wikimedia.org/event.gif?<event payload>.
    # A varnishncsa instance on the bits caches greps for these requests
    # and forwards them to eventlog* on UDP port 8422. The varnishncsa
    # configuration is specified in <manifests/role/cache.pp>.
    eventlogging::service::forwarder { 'client-side-raw':
        input => 'udp://0.0.0.0:8422',
        outputs => ["tcp://${forwarder_host}:8422"],
    }
}


# == Class role::eventlogging::processor
# Reads raw events, parses and validates them, and then sends
# them along for further consumption.
#
class role::eventlogging::processor inherits role::eventlogging {
    eventlogging::service::processor { 'server-side events':
        format  => '%{seqId}d EventLogging %j',
        input   => "tcp://${forwarder_host}:8421",
        outputs => ["tcp://${processor_host}:8521"],
    }
    eventlogging::service::processor { 'client-side events':
        format  => '%q %{recvFrom}s %{seqId}d %t %h %{userAgent}i',
        input   => "tcp://${forwarder_host}:8422",
        outputs => ["tcp://${processor_host}:8522"],
    }
}


# == Class role::eventlogging::multiplexer
# Reads multiple processed 0mq eventlogging streams and
# concatentates them into a single strream.
#
class role::eventlogging::multiplexer inherits role::eventlogging {
    # Parsed and validated client-side (varnishncsa generated) and
    # server-side (MediaWiki-generated) events are multiplexed into a
    # single output stream, published on TCP port 8600.
    eventlogging::service::multiplexer { 'all events':
        inputs => [ "tcp://${processor_host}:8521", "tcp://${processor_host}:8522" ],
        output => "tcp://${multiplexer_host}:8600",
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

    eventlogging::service::consumer { 'mysql-m4-master':
        input  => $kafka_mysql_consumer_uri,
        output => "mysql://${mysql_user}:${mysql_pass}@${mysql_db}?charset=utf8&statsd_host=${statsd_host}",
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
    # $log_dir as a medium of last resort. These files are rotated
    # and rsynced to stat1003 & stat1002 for backup.

    $log_dir = $::eventlogging::log_dir

    eventlogging::service::consumer {
        'server-side-events.log':
            input  => "tcp://${processor_host}:8421?raw=1",
            output => "file://${log_dir}/server-side-events.log";
        'client-side-events.log':
            input  => "tcp://${processor_host}:8422?raw=1",
            output => "file://${log_dir}/client-side-events.log";
        'all-events.log':
            input  => "tcp://${processor_host}:8600",
            output => "file://${log_dir}/all-events.log";
    }

    $backup_destinations = $::realm ? {
        production => [  'stat1002.eqiad.wmnet', 'stat1003.eqiad.wmnet' ],
        labs       => false,
    }

    if ( $backup_destinations ) {
        class { 'rsync::server': }

        rsync::server::module { 'eventlogging':
            path        => $log_dir,
            read_only   => 'yes',
            list        => 'yes',
            require     => File[$log_dir],
            hosts_allow => $backup_destinations,
        }
    }
}


# == Class: role::eventlogging::consumer::graphite
#
# Keeps a running count of incoming events by schema in Graphite by
# emitting 'eventlogging.SCHEMA_REVISION:1' on each event to a StatsD
# instance.
#
# The consumer connects to the host in 'input' and outputs data to the
# host in 'output'. The output host should normally be statsd
#
class role::eventlogging::consumer::graphite inherits role::eventlogging  {
    eventlogging::service::consumer { 'graphite':
        input  => "tcp://${multiplexer_host}:8600",
        output => "statsd://${statsd_host}:8125",
    }
}


# == Class role::eventlogging::reporter
#
# Sends metrics about number of events flowing through
# different parts of 0mq streams configured on this host.
#
class role::eventlogging::reporter inherits role::eventlogging {
    eventlogging::service::reporter { 'statsd':
        host => $statsd_host,
    }
}



# == Class role::eventlogging::processor::kafka
# Temporary class to test eventlogging kafka on host other than eventlog1001.
#
class role::eventlogging::processor::kafka inherits role::eventlogging {


    $kafka_consumer_args  = hiera(
        'eventlogging_processor_kafka_consumer_args',
        "auto_commit_enable=True&auto_commit_interval_ms=10000"
    )
    $kafka_consumer_group = hiera(
        'eventlogging_processor_kafka_consumer_group',
        'eventlogging-00'
    )

    eventlogging::service::processor { 'server-side-0':
        format         => '%{seqId}d EventLogging %j',
        input          => "${kafka_base_uri}?topic=eventlogging-server-side&zookeeper_connect=${kafka_zookeeper_url}&${kafka_consumer_args}",
        sid            => $kafka_consumer_group,
        outputs        => [
            $kafka_schema_uri,
            $kafka_mixed_uri
        ],
        output_invalid => true,
    }

    # Run N parallel client side processors.
    # These will auto balance amongts themselves.
    $kafka_client_side_processors = hiera(
        'eventlogging_kafka_client_side_processors',
        [
            'client-side-0',
            'client-side-1',
            'client-side-2',
            'client-side-3',
            'client-side-4',
            'client-side-5',
            'client-side-6',
            'client-side-7',
        ]
    )
    eventlogging::service::processor { $kafka_client_side_processors:
        format         => '%q %{recvFrom}s %{seqId}d %t %h %{userAgent}i',
        input          => "${kafka_base_uri}?topic=eventlogging-client-side&zookeeper_connect=${kafka_zookeeper_url}&${kafka_consumer_args}",
        sid            => $kafka_consumer_group,
        outputs        => [
            $kafka_schema_uri,
            $kafka_mixed_uri
        ],
        output_invalid => true,
    }
}
