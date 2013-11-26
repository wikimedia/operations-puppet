# == Class: nginx
#
# Nginx is a popular, high-performance HTTP server and reverse proxy.
# This module is very small and simple, providing an 'nginx::site' resource
# type that takes an Nginx configuration file as input.
#
# === Parameters
#
# [*managed*]
#   If true (the default), changes to Nginx configuration files and site
#   definition files will trigger a restart of the Nginx server. If
#   false, the service will need to be manually restarted for the
#   configuration changes to take effect.
#
class nginx(
    $managed = true,
) {
    package { [ 'nginx-full', 'nginx-full-dbg' ]: }

    service { 'nginx':
        enable     => true,
        provider   => 'debian',
        hasrestart => true,
        require    => Package['nginx-full'],
    }

    file { [ '/etc/nginx/conf.d', '/etc/nginx/sites-available', '/etc/nginx/sites-enabled' ]:
        ensure  => directory,
        recurse => true,
        purge   => true,
        force   => true,
        require => Package['nginx-full'],
    }

    if $managed {
        File <| tag == 'nginx' |> ~> Service['nginx']
    }
}
