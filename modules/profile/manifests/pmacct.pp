# == Class profile::pmacct
# Sets up a pmacct passive monitoring deployment (http://www.pmacct.net/).
# It can also produce statistics/data to kafka if configured.
#
# [*kafka_cluster*]
#   Kafka cluster configuration to use.
#   FIXME: The default version uses an indirect hiera call via kafka_config(),
#   so eventually this parameter would need to be replaced with an explicit
#   hiera call. It seems good though to explicitly isolate hiera calls in the
#   parameters as the current Puppet coding standards suggest.
#
# [*librdkafka_config*]
#   List of librdkafka configs settings specified in the format indicated
#   by upstream:
#   topic, settingX, valueX
#   global, settingY, valueY
#
#   The special value [] (empty list) can be used to avoid the creation of a librdkafka
#   configuration file and use its defaults instead.
#
class profile::pmacct (
    $kafka_cluster     = hiera('profile::pmacct::kafka_cluster'),
    $librdkafka_config = hiera('profile::pmacct::librdkafka_config'),
) {
    $kafka_config = kafka_config($kafka_cluster)
    $pmacct_librdkafka_conf = $librdkafka_config ? {
        []      => undef,
        default => $librdkafka_config,
    }

    class { '::pmacct':
        kafka_brokers     => $kafka_config['brokers']['string'],
        librdkafka_config => $pmacct_librdkafka_conf,
    }

    include ::profile::standard

    $loopbacks = [
        # eqiad
        '208.80.154.196/30',
        '2620:0:861:ffff::/64',
        # codfw
        '208.80.153.192/29',
        '2620:0:860:ffff::/64',
        # esams
        '91.198.174.244/30',
        '2620:0:862:ffff::/64',
        # ulsfo
        '198.35.26.192/30',
        '2620:0:863:ffff::/64',
        # eqsin
        '103.102.166.128/30',
        '2001:df2:e500:ffff::/56',
    ]

    ferm::service { 'bgp':
        proto  => 'tcp',
        port   => '179',
        desc   => 'BGP',
        srange => inline_template('(<%= @loopbacks.join(" ") %>)'),
    }

    ferm::service { 'netflow':
        proto  => 'udp',
        port   => '2100',
        desc   => 'NetFlow',
        srange => inline_template('(<%= @loopbacks.join(" ") %>)'),
    }
}
