#

ganglia::web::view { 'kafkatee':
    ensure => 'present',
    graphs => [
        # receive transctions per second rate
        {
            'host_regex'   => 'nosuchhost',
            'metric_regex' => 'kafka.rdkafka.brokers..+\.rx\.per_second',
            'type'         => 'stack',
        },
        # receive bytes per second rate
        {
            'host_regex'   => 'nosuchhost',
            'metric_regex' => 'kafka.rdkafka.brokers..+\.rxbytes\.per_second',
            'type'         => 'stack',
        },
        # round trip time average
        {
            'host_regex'   => 'nosuchhost',
            'metric_regex' => 'kafka.rdkafka.brokers..+\.rtt\.avg',
            'type'         => 'line',
        },
    ],
}
