class profile::logstash::eventlogging {
    require ::profile::logstash::collector

    $topic = 'eventlogging_EventError'
    $kafka_config = kafka_config('analytics')

    logstash::input::kafka { $topic:
        tags              => [$topic, 'kafka'],
        type              => 'eventlogging',
        bootstrap_servers => $kafka_config['brokers']['string'],
    }

    logstash::conf { 'filter_eventlogging':
        source   => 'puppet:///modules/profile/logstash/filter-eventlogging.conf',
        priority => 50,
    }

}
