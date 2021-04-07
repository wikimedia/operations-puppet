# vim:sw=4 ts=4 sts=4 et:
# == Class: role::logstash::elasticsearch
#
# Provisions Elasticsearch backend node for a Logstash cluster.
#
class profile::elasticsearch::logstash(
    Array[String]                 $prometheus_nodes = lookup('prometheus_nodes'),
    Optional[Stdlib::Fqdn]        $jobs_host        = lookup('profile::elasticsearch::logstash::jobs_host',    { default_value => undef }),
    Optional[Hash]                $curator_actions  = lookup('profile::elasticsearch::logstash::curator_actions', { default_value => undef }),
    Elasticsearch::InstanceParams $dc_settings      = lookup('profile::elasticsearch::dc_settings'),
) {
    include ::profile::elasticsearch

    # tasks that should only run on one host
    if $jobs_host == $::fqdn {
        include ::profile::prometheus::es_exporter

        if ($curator_actions) {
            # all curator actions from hiera: profile::elasticsearch::logstash::curator_actions
            elasticsearch::curator::job { 'cluster_wide':
                cluster_name => $dc_settings['cluster_name'],
                actions      => $curator_actions,
            }
        }
    }

    file { '/usr/share/elasticsearch/plugins':
        ensure => 'directory',
        force  => true,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    } -> Class['elasticsearch']

    $::profile::elasticsearch::configured_instances.reduce(9108) |$prometheus_port, $kv_pair| {
        $cluster_name = $kv_pair[0]
        $cluster_params = $kv_pair[1]
        $http_port = $cluster_params['http_port']

        profile::prometheus::elasticsearch_exporter { "${::hostname}:${http_port}":
            prometheus_nodes   => $prometheus_nodes,
            prometheus_port    => $prometheus_port,
            elasticsearch_port => $http_port,
        }
        $prometheus_port + 1
    }
}
