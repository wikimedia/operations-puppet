# vim:sw=4 ts=4 sts=4 et:
# == Class: role::logstash::eventlogging
#
# Configure Logstash to consume validation logs from EventLogging.
#
# filtertags: labs-project-deployment-prep
class role::logstash::eventlogging {
    include ::role::logstash::collector

    $topic = 'eventlogging_EventError'
    $kafka_config = kafka_config('analytics')

    # some environments (like deployment-prep) don't have access to the
    # analytics kafka cluster, so let's guard against that
    if $kafka_config != undef {
        logstash::input::kafka { $topic:
            tags              => [$topic, 'kafka'],
            type              => 'eventlogging',
            bootstrap_servers => $kafka_config['brokers']['string'],
        }
    }
    logstash::conf { 'filter_eventlogging':
        source   => 'puppet:///modules/role/logstash/filter-eventlogging.conf',
        priority => 50,
    }
}
