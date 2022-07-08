# SPDX-License-Identifier: Apache-2.0
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
#   'nginx-full', 'nginx-light' or 'nginx-extras' packages on Stretch,
#   Buster and Bullseye. Starting with Bookworm there is a single nginx
#   and additional functionality can be installed via libnginx-mod-http-foo
#   packages. Use "custom" and the modules parameter to configure that scheme.
#
# [*modules]
#   When using the "custom" variant, install this list of additional modules.
#   Only the module name needs to be passed, so e.g. echo to install the
#   packaged libnginx-mod-http-echo module
#
# @param lib_on_tmpfs Mount /var/lib/nginx on a tmpfs volume to reduce disk
#        writes
# @param tmpfs_size The /var/lib/nginx tmpfs size
class nginx(
    Wmflib::Ensure                            $ensure = 'present',
    Boolean                                   $managed = true,
    Enum['full', 'extras', 'light', 'custom'] $variant = 'full',
    Boolean                                   $lib_on_tmpfs = true,
    String                                    $tmpfs_size = '1g',
    Array[String]                             $modules = [],
){

    if $variant == 'custom' {
        $nginx_package_name = 'nginx'
        if debian::codename::lt('bookworm') {
            fail('The custom variant is only available for Bookworm and later')
        }

        ensure_packages ([$nginx_package_name], {'ensure' => $ensure})

        $modules.each |String $module| {
            ensure_packages (["libnginx-mod-http-${module}"], {'ensure' => $ensure})
        }
    } else {
        $nginx_package_name = "nginx-${variant}"
        ensure_packages ([$nginx_package_name,'nginx-common'], {'ensure' => $ensure})
    }

    # In the unmanaged case, this prevents the scenario where after the
    # initial puppet run that installs the package, the net resulting state is
    # a fully deployed configuration on disk, but the running instance still
    # running the default configuration from the package.  With this, it gets
    # stopped before the service clause checks->starts it with good config.
    if ! $managed and ($ensure == 'present') {
        exec { 'stop-default-nginx':
            command     => '/usr/sbin/service nginx stop',
            subscribe   => Package[$nginx_package_name],
            refreshonly => true,
            before      => Service['nginx'],
        }
    }

    service { 'nginx':
        ensure     => stdlib::ensure($ensure, 'service'),
        enable     => ($ensure == 'present'),
        hasrestart => true,
        require    => Package[$nginx_package_name],
    }

    exec { 'nginx-reload':
        command     => '/usr/sbin/service nginx reload',
        refreshonly => true,
    }

    file { '/etc/nginx':
        ensure  => directory,
        require => Package[$nginx_package_name],
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
            ensure => $ensure,
            source => 'puppet:///modules/nginx/prometheus.lua',
        }
    }

    # Order config -> service for all
    #  nginx-tagged config files (including all File resources
    #  declared within this module), and set up the
    #  notification for config~>service if $managed.
    # Also set up ssl tag -> service similarly, for certs
    if $managed {
        File <| tag == 'nginx' |> ~> Service['nginx']
        File <| tag == 'ssl' |> ~> Service['nginx']
    }
    else {
        File <| tag == 'nginx' |> -> Service['nginx']
        File <| tag == 'ssl' |> -> Service['nginx']
    }

    if $lib_on_tmpfs {
        # nginx will buffer e.g. large body content into this directory
        #  very briefly, so keep it off the disks.
        file { '/var/lib/nginx':
            ensure => directory,
        }
        mount { '/var/lib/nginx':
            ensure  => stdlib::ensure($ensure, 'mounted'),
            device  => 'tmpfs',
            fstype  => 'tmpfs',
            options => "defaults,noatime,uid=0,gid=0,mode=755,size=${tmpfs_size}",
            pass    => 0,
            dump    => 0,
            before  => Service['nginx'],
            require => File['/var/lib/nginx'],
        }
    }
}
