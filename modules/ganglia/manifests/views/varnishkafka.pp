define ganglia::views::varnishkafka(
    $varnishkafka_host_regex = 'cp.+',
    $topic_regex = '.+',
    $ensure = 'present') {

    ganglia::web::view { "varnishkafka-${title}":
        ensure => $ensure,
        graphs => [
            # delivery report error rate
            {
                'host_regex'   => $varnishkafka_host_regex,
                'metric_regex' => 'kafka.varnishkafka\.kafka_drerr.per_second',
                'type'         => 'line',
            },
            # delivery report errors.
            # drerr is important, but seems to happen in bursts.
            # let's show the total drerr in the view as well.
            {
                'host_regex'   => $varnishkafka_host_regex,
                'metric_regex' => 'kafka.varnishkafka\.kafka_drerr$',
                'type'         => 'line',
            },
            # transaction error rate
            {
                'host_regex'   => $varnishkafka_host_regex,
                'metric_regex' => 'kafka.varnishkafka\.txerr.per_second',
                'type'         => 'line',
            },

            # round trip time average
            {
                'host_regex'   => $varnishkafka_host_regex,
                'metric_regex' => 'kafka.rdkafka.brokers..+\.rtt\.avg',
                'type'         => 'line',
            },


            ## These graphs are large, and I don't use them much. Disabling them in this view for now.
            ## https://phabricator.wikimedia.org/T97637
            # Queues:
            #   msgq -> xmit_msgq -> outbuf -> waitresp

            # # message queue count
            # {
            #     'host_regex'   => $varnishkafka_host_regex,
            #     'metric_regex' => "kafka.rdkafka.topics.${topic_regex}\\.msgq_cnt",
            #     'type'         => 'line',
            # },
            # # transmit message queue count
            # {
            #     'host_regex'   => $varnishkafka_host_regex,
            #     'metric_regex' => "kafka.rdkafka.topics.${topic_regex}\\.xmit_msgq_cnt",
            #     'type'         => 'line',
            # },
            # # output buffer queue count
            # {
            #     'host_regex'   => $varnishkafka_host_regex,
            #     'metric_regex' => 'kafka.rdkafka.brokers..+\.outbuf_cnt',
            #     'type'         => 'line',
            # },
            # # waiting for response buffer count
            # {
            #     'host_regex'   => $varnishkafka_host_regex,
            #     'metric_regex' => 'kafka.rdkafka.brokers..+\.waitresp_cnt',
            #     'type'         => 'line',
            # },
            #
            # # transaction bytes rate
            # {
            #     'host_regex'   => $varnishkafka_host_regex,
            #     'metric_regex' => "kafka.rdkafka.topics.${topic_regex}\\.txbytes.per_second",
            #     'type'         => 'stack',
            # },

            # transaction messages rate
            {
                'host_regex'   => $varnishkafka_host_regex,
                'metric_regex' => "kafka.rdkafka.topics.${topic_regex}\\.txmsgs.per_second",
                'type'         => 'stack',
            },
        ],
    }
}

