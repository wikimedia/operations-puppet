# == Class: profile::elasticsearch::toolforge
#
# Provisions Elasticsearch node with nginx reverse proxy
#
# filtertags: labs-project-tools
class profile::elasticsearch::toolforge {
    include ::profile::elasticsearch

    file { '/usr/share/elasticsearch/plugins':
        ensure => 'directory',
        force  => true,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        before => Class['::elasticsearch'],
    }
}
