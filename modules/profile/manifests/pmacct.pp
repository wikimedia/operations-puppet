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

    ensure_resource('class', 'geoip')

    class { '::pmacct':
        kafka_brokers     => $kafka_config['brokers']['string'],
        librdkafka_config => $pmacct_librdkafka_conf,
        networks          => $::network::constants::external_networks,
    }

    include ::profile::standard

    ferm::service { 'bgp':
        proto  => 'tcp',
        port   => '179',
        desc   => 'BGP',
        srange => '($NETWORK_INFRA $MGMT_NETWORKS)',
    }

    ferm::service { 'netflow':
        proto  => 'udp',
        port   => '2100',
        desc   => 'NetFlow',
        srange => '($NETWORK_INFRA $MGMT_NETWORKS)',
    }
}
