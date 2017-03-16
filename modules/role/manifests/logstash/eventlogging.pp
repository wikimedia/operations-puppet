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

    logstash::input::kafka { $topic:
        tags              => [$topic, 'kafka'],
        type              => 'eventlogging',
        bootstrap_servers => $kafka_config['brokers']['string'],
    }
    # lint:ignore:puppet_url_without_modules
    logstash::conf { 'filter_eventlogging':
        source   => 'puppet:///modules/role/logstash/filter-eventlogging.conf',
        priority => 50,
    }
    # lint:endignore
}
