# misc/monitoring.pp

# Ganglia views that should be
# avaliable on ganglia.wikimedia.org
class misc::monitoring::views {
    misc::monitoring::view::varnishkafka { 'webrequest':
        topic_regex => 'webrequest_.+',
    }

    include misc::monitoring::views::dns
}

class misc::monitoring::views::dns {
    $auth_dns_host_regex = '^(radon|baham|eeden)\.'
    $rec_dns_host_regex = '^(chromium|hydrogen|acamar|achernar|maerlant|nescio)\.'

    ganglia::web::view { 'authoritative_dns':
        ensure      => 'present',
        description => 'DNS Authoritative',
        graphs      => [
            {
            'title'        => 'DNS UDP Requests',
            'host_regex'   => $auth_dns_host_regex,
            'metric_regex' => '^gdnsd_udp_reqs$',
            'type'         => 'stack',
            },
            {
            'title'        => 'DNS TCP Requests',
            'host_regex'   => $auth_dns_host_regex,
            'metric_regex' => '^gdnsd_tcp_reqs$',
            'type'         => 'stack',
            },
            {
            'title'        => 'DNS NXDOMAIN',
            'host_regex'   => $auth_dns_host_regex,
            'metric_regex' => '^gdnsd_stats_nxdomain$',
            'type'         => 'stack',
            },
            {
            'title'        => 'DNS REFUSED',
            'host_regex'   => $auth_dns_host_regex,
            'metric_regex' => '^gdnsd_stats_refused$',
            'type'         => 'stack',
            },
            {
            'title'        => 'DNS queries over IPv6',
            'host_regex'   => $auth_dns_host_regex,
            'metric_regex' => '^gdnsd_stats_v6$',
            'type'         => 'stack',
            },
            {
            'title'        => 'DNS EDNS Client Subnet requests',
            'host_regex'   => $auth_dns_host_regex,
            'metric_regex' => '^gdnsd_stats_edns_clientsub$',
            'type'         => 'stack',
            },
        ]
    }

    ganglia::web::view { 'recursive_dns':
        ensure      => 'present',
        description => 'DNS Recursive',
        graphs      => [
            {
            'title'        => 'DNS Outgoing queries',
            'host_regex'   => $rec_dns_host_regex,
            'metric_regex' => '^pdns_all-outqueries$',
            'type'         => 'stack',
            },
            {
            'title'        => 'DNS Answers',
            'host_regex'   => $rec_dns_host_regex,
            'metric_regex' => '^pdns_answers.*$',
            'type'         => 'stack',
            },
            {
            'title'        => 'DNS cache',
            'host_regex'   => $rec_dns_host_regex,
            'metric_regex' => '^pdns_cache-.*$',
            'type'         => 'stack',
            },
            {
            'title'        => 'DNS IPv6 Outgoing queries',
            'host_regex'   => $rec_dns_host_regex,
            'metric_regex' => '^pdns_ipv6-outqueries$',
            'type'         => 'stack',
            },
            {
            'title'        => 'DNS Incoming queries',
            'host_regex'   => $rec_dns_host_regex,
            'metric_regex' => '^pdns_questions$',
            'type'         => 'stack',
            },
            {
            'title'        => 'DNS Servfails',
            'host_regex'   => $rec_dns_host_regex,
            'metric_regex' => '^pdns_servfail-asnwers$',
            'type'         => 'stack',
            },
            {
            'title'        => 'DNS NXDOMAIN',
            'host_regex'   => $rec_dns_host_regex,
            'metric_regex' => '^pdns_nxdomain-asnwers$',
            'type'         => 'stack',
            },
        ]
    }
}

# == Define misc::monitoring::view::varnishkafka
#
define misc::monitoring::view::varnishkafka($varnishkafka_host_regex = 'cp.+', $topic_regex = '.+', $ensure = 'present') {
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


# == Class misc::monitoring::view::kafkatee
#
class misc::monitoring::view::kafkatee($kafkatee_host_regex, $topic_regex = '.+', $ensure = 'present') {
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


# == Class misc::monitoring::view::analytics::data
# View for analytics data flow.
# This is a class instead of a define because it is specific enough to never need
# multiple instances.
#
# == Parameters
# $hdfs_stat_host            - host on which the webrequest_loss_percentage metric is gathered.
# $kafka_broker_host_regex   - regex matching kafka broker hosts
# $kafka_producer_host_regex - regex matching kafka producer hosts, this is the same as upd2log hosts
#
class misc::monitoring::view::analytics::data($hdfs_stat_host, $kafka_broker_host_regex, $kafka_producer_host_regex, $ensure = 'present') {
    ganglia::web::view { 'analytics-data':
        ensure => $ensure,
        graphs => [
            {
                'host_regex'   => $kafka_producer_host_regex,
                'metric_regex' => '^packet_loss_average$',
            },
            {
                'host_regex'   => $kafka_producer_host_regex,
                'metric_regex' => 'udp2log_kafka_producer_.+.AsyncProducerEvents',
                'type'         => 'stack',
            },
            {
                'host_regex'   => $kafka_broker_host_regex,
                'metric_regex' => 'kafka_network_SocketServerStats.ProduceRequestsPerSecond',
                'type'         => 'stack',
            },
            {
                'host_regex'   => $hdfs_stat_host,
                'metric_regex' => 'webrequest_loss_average',
            },
        ],
    }
}
