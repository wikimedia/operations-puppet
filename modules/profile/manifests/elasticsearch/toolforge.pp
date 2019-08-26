# == Class: profile::elasticsearch::toolforge
#
# Provisions Elasticsearch node with nginx reverse proxy
#
# filtertags: labs-project-tools
class profile::elasticsearch::toolforge (
    Array[Stdlib::Fqdn] $prometheus_nodes = lookup('prometheus_nodes')
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
    $prometheus_hosts = join($prometheus_nodes, ' ')
    # So prometheus blackbox exporter can monitor ssh
    ferm::service { 'ssh-prometheus':
        proto  => 'tcp',
        port   => '22',
        srange => "@resolve((${prometheus_hosts}))",
    }
}
