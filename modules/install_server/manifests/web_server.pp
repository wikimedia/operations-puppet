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

    $nginx_ssl_conf = ssl_ciphersuite('nginx', 'compat')
    file { '/etc/nginx/nginx.conf':
        content => template('install_server/nginx.conf.erb'),
        tag     => 'nginx',
    }

    nginx::site { 'install_server':
        content => template('install_server/install_server.conf.erb'),
    }

    nginx::site { 'apt.wikimedia.org':
        source  => 'puppet:///modules/install_server/apt.wikimedia.org.conf',
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
