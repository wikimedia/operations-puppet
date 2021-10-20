# == Class: profile::elasticsearch::toolforge
#
# Provisions Elasticsearch node with nginx reverse proxy
#
class profile::elasticsearch::toolforge (
    Array[Stdlib::Fqdn] $prometheus_nodes = lookup('prometheus_nodes'),
    Elasticsearch::InstanceParams $elastic_settings = lookup('profile::elasticsearch::common_settings'),
){
    include ::profile::elasticsearch

    file { '/usr/share/elasticsearch/plugins':
        ensure => 'directory',
        force  => true,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        before => Class['::elasticsearch'],
    }

    prometheus::elasticsearch_exporter { "localhost:${elastic_settings['http_port']}":
        prometheus_port    => 9108,
        elasticsearch_port => $elastic_settings['http_port'],
    }

    $prometheus_hosts = join($prometheus_nodes, ' ')
    # So prometheus blackbox exporter can monitor ssh
    ferm::service { 'ssh-prometheus':
        proto  => 'tcp',
        port   => '22',
        srange => "@resolve((${prometheus_hosts}))",
    }

    ferm::service { 'prometheus_elasticsearch_exporter_9108':
        proto  => 'tcp',
        port   => 9108,
        srange => "@resolve((${prometheus_hosts}))",
    }

}
