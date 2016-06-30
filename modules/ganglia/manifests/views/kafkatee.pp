class ganglia::views::kafkatee(
    $kafkatee_host_regex,
    $topic_regex = '.+',
    $ensure = 'present') {

    ganglia::web::view { 'kafkatee':
        ensure => $ensure,
        graphs => [
            # receive transctions per second rate
            {
                'host_regex'   => $kafkatee_host_regex,
                'metric_regex' => 'kafka.rdkafka.brokers..+\.rx\.per_second',
                'type'         => 'stack',
            },
            # receive bytes per second rate
            {
                'host_regex'   => $kafkatee_host_regex,
                'metric_regex' => 'kafka.rdkafka.brokers..+\.rxbytes\.per_second',
                'type'         => 'stack',
            },
            # round trip time average
            {
                'host_regex'   => $kafkatee_host_regex,
                'metric_regex' => 'kafka.rdkafka.brokers..+\.rtt\.avg',
                'type'         => 'line',
            },
            # next_offset.per_second - rate at which offset is updated,
            # meaning how many offsets per second are read
            {
                'host_regex'   => $kafkatee_host_regex,
                'metric_regex' => "kafka.rdkafka.topics.${topic_regex}\\.next_offset.per_second",
                'type'         => 'stack',
            },
        ],
    }
}

