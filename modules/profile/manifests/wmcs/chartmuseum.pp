# SPDX-License-Identifier: Apache-2.0
#
# Simple profile to create a trivial chartmuseum instance on a cloud-vps instance
#
class profile::wmcs::chartmuseum(
    Stdlib::Host               $listen_host      = lookup('profile::wmcs::chartmuseum::listen_host', {default_value => '0.0.0.0'}),
    Stdlib::Port::Unprivileged $listen_port      = lookup('profile::wmcs::chartmuseum::listen_port', {default_value => 8080}),
    Integer[0]                 $repository_depth = lookup('profile::wmcs::chartmuseum::repository_depth', {default_value => 0}),
    Boolean                    $debug            = lookup('profile::wmcs::chartmuseum::debug', {default_value => false}),
) {
    class { '::chartmuseum':
        listen_host         => $listen_host,
        listen_port         => $listen_port,
        repository_depth    => $repository_depth,
        allow_anonymous_get => true,
        debug               => $debug,
        require             => File['/var/lib/chartmuseum'],
    }

    file { '/srv/chartmuseum':
        ensure => 'directory',
        owner  => 'chartmuseum',
        group  => 'chartmuseum',
    }

    file { '/var/lib/chartmuseum':
        ensure  => 'link',
        target  => '/srv/chartmuseum',
        require => File['/srv/chartmuseum'],
    }

    class { '::helm':
        helm_user_group => root,
    }
}
