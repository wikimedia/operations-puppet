# == Class: role::toollabs::elasticsearch
#
# Provisions Elasticsearch node with nginx reverse proxy
#
# filtertags: labs-project-tools
class role::toollabs::elasticsearch {
    include ::toollabs::base
    include ::profile::base::firewall
    include ::profile::elasticsearch::toolforge

    class { '::nginx':
        variant => 'light',
    }

    $auth_realm = 'Elasticsearch protected actions'
    $auth_file = '/etc/nginx/elasticsearch.htpasswd'
    nginx::site { 'elasticsearch':
        content => template('role/toollabs/elasticsearch/nginx.conf.erb'),
    }

    file { '/etc/nginx/elasticsearch.htpasswd':
        ensure    => present,
        owner     => 'root',
        group     => 'www-data',
        mode      => '0440',
        content   => secret('labs/toollabs/elasticsearch/htpasswd'),
        show_diff => false,
        require   => Class['nginx'],
    }

    ferm::service{ 'nginx-http':
        proto   => 'tcp',
        port    => 80,
        notrack => true,
    }
}
