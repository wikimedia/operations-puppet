# == Class: role::toollabs::elasticsearch
#
# Provisions Elasticsearch node with nginx reverse proxy
#
# filtertags: labs-project-tools
class role::toollabs::elasticsearch {
    include ::base::firewall
    include ::elasticsearch

    class { '::nginx':
        variant => 'light',
    }

    $auth_realm = 'Elasticsearch protected actions'
    $auth_file = '/etc/nginx/elasticsearch.htpasswd'
    nginx::site { 'elasticsearch':
        content => template('role/toollabs/elasticsearch/nginx.conf.erb'),
    }

    file { '/etc/nginx/elasticsearch.htpasswd':
        ensure  => present,
        owner   => 'root',
        group   => 'www-data',
        mode    => '0440',
        content => secret('labs/toollabs/elasticsearch/htpasswd'),
        require => Class['nginx'],
    }

    ferm::service{ 'nginx-http':
        proto   => 'tcp',
        port    => 80,
        notrack => true,
    }

    $unicast_hosts = hiera('elasticsearch::unicast_hosts')
    $unicast_hosts_ferm = join($unicast_hosts, ' ')
    ferm::service { 'logstash_elastic_internode':
        proto   => 'tcp',
        port    => 9300,
        notrack => true,
        srange  => "@resolve((${unicast_hosts_ferm}))",
    }
}
