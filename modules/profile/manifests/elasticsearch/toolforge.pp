# == Class: profile::elasticsearch::toolforge
#
# Provisions Elasticsearch node with nginx reverse proxy
#
class profile::elasticsearch::toolforge (
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
}
