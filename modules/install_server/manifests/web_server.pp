# Class: install_server::web_server
#
# This class installs and configures nginx to act as a repository for new
# installation enviroments
#
# Parameters:
#
# Actions:
#   Install and configure nginx
#
# Requires:
#
# Sample Usage:
#   include install_server::web_server

class install_server::web_server {
    include ::nginx

    letsencrypt::cert::integrated { 'apt':
        subjects   => 'apt.wikimedia.org',
        puppet_svc => 'nginx',
        system_svc => 'nginx',
    }
    # TODO: Monitor SSL?


    $ssl_settings = ssl_ciphersuite('nginx', 'mid', true)

    file { '/etc/nginx/nginx.conf':
        content => template('install_server/nginx.conf.erb'),
        tag     => 'nginx',
    }

    nginx::site { 'apt.wikimedia.org':
        content => template('install_server/apt.wikimedia.org.conf.erb'),
    }

    # prevent a /srv root autoindex; empty for now.
    file { '/srv/index.html':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => '',
    }
}
