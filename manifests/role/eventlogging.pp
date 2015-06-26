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
    class { '::eventlogging': }

    # Infer Kafka cluster configuration from this class
    class { 'role::analytics::kafka::config': }

    if hiera('has_ganglia', true) {
        class { 'role::eventlogging::monitoring': }
    }

    system::role { 'role::eventlogging':
        description => 'EventLogging',
    }

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

    $kafka_brokers_array = $role::analytics::kafka::config::brokers_array
    # By default, the EL Kafka writer writes events to
    # schema based topic names like eventlogging_SCHEMA,
    # with each message keyed by SCHEMA_REVISION.
    $kafka_output_uri    = inline_template('kafka:///<%= @kafka_brokers_array.join(":9092,") + ":9092" %>')

    # jq is very useful, install it on eventlogging servers
    ensure_packages(['jq'])
}


#### Data flow classes ####
# udp://{client,server}-side-raw
#   -> tcp://{client,server}-side-raw       (forwarders)
#   -> tcp://{client,server}-side-processed (processors)
#   -> tcp://all-processed                  (multiplexer)
#       -> mysql://all, files://...         (consumer)
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
        outputs => ["tcp://${forwarder_host}:8421"],
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
        input  => "tcp://${processor_host}:8600",
        output => "mysql://${mysql_user}:${mysql_pass}@${mysql_db}?charset=utf8",
        # Restrict permissions on this config file since it contains a password.
        owner  => 'root',
        group  => 'eventlogging',
        mode   => '0640',
    }
}

# == Class role::eventlogging::consumer::files
# Consumes streams of events and writes them to log files.
class role::eventlogging::consumer::files inherits role::eventlogging {
    ## Flat files

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

# == Class role::eventlogging::processor::kafka
# Temporary class to test eventlogging kafka on host other than eventlog1001.
#
class role::eventlogging::processor::kafka inherits role::eventlogging {
    # Read in server side and client side raw events from
    # ZeroMQ, process them, and send events to schema
    # based topics in Kafka.
    eventlogging::service::processor { 'server-side-events-kafka':
        format         => '%{seqId}d EventLogging %j',
        input          => "tcp://${forwarder_host}:8421",
        outputs         => [$kafka_output_uri],
        output_invalid => true,
    }
    eventlogging::service::processor { 'client-side-events-kafka':
        format         => '%q %{recvFrom}s %{seqId}d %t %h %{userAgent}i',
        input          => "tcp://${forwarder_host}:8422",
        outputs         => [$kafka_output_uri],
        output_invalid => true,
    }
}

# == Class: role::eventlogging::monitoring
#
# Provisions scripts for reporting state to monitoring tools.
#
class role::eventlogging::monitoring inherits role::eventlogging {
    class { '::eventlogging::monitoring': }

    eventlogging::service::reporter { 'statsd':
        host => 'statsd.eqiad.wmnet',
    }

    nrpe::monitor_service { 'eventlogging':
        ensure        => 'present',
        description   => 'Check status of defined EventLogging jobs',
        nrpe_command  => '/usr/lib/nagios/plugins/check_eventlogging_jobs',
        require       => File['/usr/lib/nagios/plugins/check_eventlogging_jobs'],
        contact_group => 'admins,analytics',
    }

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


# == Class: role::eventlogging::graphite
#
# Keeps a running count of incoming events by schema in Graphite by
# emitting 'eventlogging.SCHEMA_REVISION:1' on each event to a StatsD
# instance.

# The consumer connects to the host in 'input' and outputs data to the
# host in 'output'. The output host should normally be statsd
#
# Includes process nanny alarm for graphite consumer

class role::eventlogging::graphite inherits role::eventlogging  {
    class { '::eventlogging::monitoring': }

    eventlogging::service::consumer { 'graphite':
        input  => "tcp://${processor_host}:8600",
        output => 'statsd://statsd.eqiad.wmnet:8125',
    }

    # Generate icinga alert if the graphite consumer is not running.
    nrpe::monitor_service { 'eventlogging':
        ensure        => 'present',
        description   => 'Check status of defined EventLogging jobs on graphite consumer',
        nrpe_command  => '/usr/lib/nagios/plugins/check_eventlogging_jobs',
        require       => File['/usr/lib/nagios/plugins/check_eventlogging_jobs'],
        contact_group => 'admins,analytics',
    }

}
