# == Class: nginx
#
# Nginx is a popular, high-performance HTTP server and reverse proxy.
# This module is very small and simple, providing an 'nginx::site' resource
# type that takes an Nginx configuration file as input.
#
# This also installs the nginx-common package by default explicitly, so
# other code can require that package to do things after install but potentially
# before the service starts.
#
# === Parameters
#
# [*managed*]
#   If true (the default), changes to Nginx configuration files and site
#   definition files will trigger a restart of the Nginx server. If
#   false, the service will need to be manually restarted for the
#   configuration changes to take effect.
#
# [*variant*]
#   Which variant of the nginx package to install. Must be one of
#   'full', 'light' or 'extras', which respectively install one of
#   'nginx-full', 'nginx-light' or 'nginx-extras' packages.
#
class nginx(
    Wmflib::Ensure                  $ensure = 'present',
    Boolean                         $managed = true,
    Enum['full', 'extras', 'light'] $variant = 'full',
    String                          $tmpfs_size = '1g',
){

    package { [ "nginx-${variant}", 'nginx-common' ]:
        ensure => $ensure,
    }

    # In the unmanaged case, this prevents the scenario where after the
    # initial puppet run that installs the package, the net resulting state is
    # a fully deployed configuration on disk, but the running instance still
    # running the default configuration from the package.  With this, it gets
    # stopped before the service clause checks->starts it with good config.
    if ! $managed and ($ensure == 'present') {
        exec { 'stop-default-nginx':
            command     => '/usr/sbin/service nginx stop',
            subscribe   => Package["nginx-${variant}"],
            refreshonly => true,
            before      => Service['nginx'],
        }
    }

    service { 'nginx':
        ensure     => stdlib::ensure($ensure, 'service'),
        enable     => ($ensure == 'present'),
        provider   => 'debian',
        hasrestart => true,
    }

    exec { 'nginx-reload':
        command     => '/usr/sbin/service nginx reload',
        refreshonly => true,
    }

    file { [ '/etc/nginx/conf.d', '/etc/nginx/sites-available', '/etc/nginx/sites-enabled' ]:
        ensure  => stdlib::ensure($ensure, 'directory'),
        recurse => true,
        purge   => true,
        force   => true,
        tag     => 'nginx', # workaround PUP-2689, can remove w/ puppetmaster 3.6.2+
    }

    if $variant == 'extras' {
        file { '/etc/nginx/prometheus.lua':
            ensure  => $ensure,
            source  => 'puppet:///modules/nginx/prometheus.lua',
            require => Package["nginx-${variant}"],
        }
    }

    # Order package -> config -> service for all
    #  nginx-tagged config files (including all File resources
    #  declared within this module), and set up the
    #  notification for config~>service if $managed.
    # Also set up ssl tag -> service similarly, for certs
    Package["nginx-${variant}"] -> File <| tag == 'nginx' |>
    if $managed {
        File <| tag == 'nginx' |> ~> Service['nginx']
        File <| tag == 'ssl' |> ~> Service['nginx']
    }
    else {
        File <| tag == 'nginx' |> -> Service['nginx']
        File <| tag == 'ssl' |> -> Service['nginx']
    }

    if $::realm == 'production' {
        # nginx will buffer e.g. large body content into this directory
        #  very briefly, so keep it off the disks.
        mount { '/var/lib/nginx':
            ensure  => stdlib::ensure($ensure, 'mounted'),
            device  => 'tmpfs',
            fstype  => 'tmpfs',
            options => "defaults,noatime,uid=0,gid=0,mode=755,size=${tmpfs_size}",
            pass    => 0,
            dump    => 0,
            before  => Service['nginx'],
            require => Package["nginx-${variant}"],
        }
    }
}
