# == Class role::eventlogging::analytics::server
# Common role class that all other eventlogging analytics role classes should include.
#
class role::eventlogging::analytics::server {
    system::role { 'role::eventlogging::analytics':
        description => 'EventLogging analytics processes',
    }

    # EventLogging for analytics processing is deployed
    # as the eventlogging/analytics scap target.
    eventlogging::deployment::target { 'analytics': }
    class { 'eventlogging::server':
        eventlogging_path => '/srv/deployment/eventlogging/analytics'
    }

    # Get the Kafka configuration
    $kafka_config         = kafka_config('analytics')
    $kafka_brokers_string = $kafka_config['brokers']['string']

    # Using kafka-confluent as a consumer is not currently supported by this puppet module,
    # but is implemented in eventlogging.  Hardcode the scheme for consumers for now.
    $kafka_consumer_scheme = 'kafka://'

    # Commonly used Kafka input URIs.
    $kafka_mixed_uri = "${kafka_consumer_scheme}/${kafka_brokers_string}?topic=eventlogging-valid-mixed",
    $kafka_client_side_raw_uri = "${kafka_consumer_scheme}/${kafka_brokers_string}?topic=eventlogging-client-side"

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

    # make sure any defined eventlogging services are running
    class { '::eventlogging::monitoring::jobs': }
}

