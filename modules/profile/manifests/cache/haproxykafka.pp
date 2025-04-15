# SPDX-License-Identifier: Apache-2.0
# == Class: profile::cache::haproxykafka
#
# Deploy haproxykafka instance with configuration and relative
# auxiliary files
#
class profile::cache::haproxykafka(
    Wmflib::Ensure $ensure                        = lookup('profile::cache::haproxykafka::ensure'),
    String $haproxykafka_user                     = lookup('profile::cache::haproxykafka::user'),
    String $kafka_cluster_name                    = lookup('profile::cache::haproxykafka::kafka_cluster_name'),
    Integer $workers                              = lookup('profile::cache::haproxykafka::workers'),
    Float $message_buffer                         = lookup('profile::cache::haproxykafka::message_buffer'),
    String $sdid                                  = lookup('profile::cache::haproxykafka::sdid'),
    String $hostname                              = lookup('profile::cache::haproxykafka::hostname'),
    Haproxykafka::Socket $socket                  = lookup('profile::cache::haproxykafka::socket'),
    Haproxykafka::Logparser $logparser            = lookup('profile::cache::haproxykafka::logparser'),
    Haproxykafka::Kafka $kafka                    = lookup('profile::cache::haproxykafka::kafka'),
    Haproxykafka::Monitoring $monitoring          = lookup('profile::cache::haproxykafka::monitoring'),
    Haproxykafka::Transformrules $transform_rules = lookup('profile::cache::haproxykafka::transform_rules'),
) {

    $kafka_cluster_cfg = kafka_config($kafka_cluster_name)
    # that could not be defined in cloud environments
    $bootstrap_servers = $kafka_cluster_cfg ? {
        Undef => {
            'rdkafka' => {
                'bootstrap.servers' => '',
            },
        },
        default => {
            'rdkafka' => {
                'bootstrap.servers' => $kafka_cluster_cfg['brokers']['ssl_string']
            },
        },
    }

    $ssl_dir = '/etc/haproxykafka/ssl'

    file { $ssl_dir:
        ensure => stdlib::ensure($ensure, 'directory'),
        force  => true,
    }

    if $ensure == 'present' {
        $ssl_files = profile::pki::get_cert('kafka', 'haproxykafka', {
                'outdir'  => $ssl_dir,
                'owner'   => $haproxykafka_user,
                'group'   => 'root',
                'profile' => 'kafka_11',
                notify    => Service['haproxykafka'],
                require   => [File[$ssl_dir], User[$haproxykafka_user]],
        })
        $ssl_conf = {
            'rdkafka' => {
                'ssl.key.location' => $ssl_files['key'],
                'ssl.certificate.location' => $ssl_files['chained'],
            },
        }
    } else {
        $ssl_conf = {}
    }


    $config = {
        workers         => $workers,
        message_buffer  => $message_buffer,
        sdid            => $sdid,
        hostname        => $hostname,
        socket          => $socket,
        logparser       => $logparser,
        kafka           => deep_merge($kafka, $bootstrap_servers, $ssl_conf),
        monitoring      => $monitoring,
        transform_rules => $transform_rules,
    }

    class { 'haproxykafka':
        ensure => $ensure,
        config => $config,
        user   => $haproxykafka_user,
    }
}
