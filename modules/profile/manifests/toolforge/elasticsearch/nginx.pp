class profile::toolforge::elasticsearch::nginx(
) {
    class { '::nginx':
        variant => 'light',
    }

    $auth_realm = 'Elasticsearch protected actions'
    $auth_file = '/etc/nginx/elasticsearch.htpasswd'
    nginx::site { 'elasticsearch':
        content => template('profile/toolforge/elasticsearch/nginx.conf.erb'),
    }

    file { '/etc/nginx/elasticsearch.htpasswd':
        ensure    => present,
        owner     => 'root',
        group     => 'www-data',
        mode      => '0440',
        content   => secret('labs/toollabs/elasticsearch/htpasswd'),
        show_diff => false,
        require   => Package['nginx-common'], # deploys /etc/nginx
    }

    ferm::service { 'nginx-http':
        proto   => 'tcp',
        port    => 80,
        notrack => true,
    }
}
