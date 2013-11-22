# == Class: nginx
#
# Nginx is a popular, high-performance HTTP server and reverse proxy.
# This module is very small and simple, providing an 'nginx::site' resource
# type that takes an Nginx configuration file as input.
#
# You don't need to include this class in your manifests; declaring an
# nginx::site resource will pull it in automatically.
#
class nginx {
    package { [ 'nginx-full', 'nginx-full-dbg' ]: }

    file { [ '/etc/nginx/sites-enabled', '/etc/nginx/sites-available', '/etc/nginx/conf.d' ]:
        ensure  => directory,
        recurse => true,
        purge   => true,
        force   => true,
        require => Package['nginx-full'],
        notify  => Service['nginx'],
    }

    service { 'nginx':
        ensure   => running,
        enable   => true,
        provider => 'debian',
        require  => Package['nginx-full'],
    }
}
