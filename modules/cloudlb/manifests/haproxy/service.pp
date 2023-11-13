# SPDX-License-Identifier: Apache-2.0
define cloudlb::haproxy::service (
    CloudLB::HAProxy::Service::Definition $service,
) {
    # shortcuts
    if $service['backend']['servers'] =~ Array[Stdlib::Fqdn] {
        $servers = $service['backend']['servers']
    } else {
        $servers = $service['backend']['servers'].map |OpenStack::ControlNode $node| {
            $node['cloud_private_fqdn']
        }
    }

    $port_backend = $service['backend']['port']
    $frontends = $service['frontends']
    $type = $service['type']
    $open_firewall = $service['open_firewall']
    $healthcheck_options = $service['healthcheck']['options']
    $healthcheck_method = $service['healthcheck']['method']
    $healthcheck_path = $service['healthcheck']['path']
    $firewall = $service['firewall']
    $http = $service['http']

    if $type == 'http' {
        file { "/etc/haproxy/conf.d/${title}.cfg":
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('cloudlb/haproxy/conf.d/http-service.cfg.erb'),
            # restart to pick up new config files in conf.d
            notify  => Service['haproxy'],
        }
    } elsif $type == 'tcp' {
        file { "/etc/haproxy/conf.d/${title}.cfg":
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('cloudlb/haproxy/conf.d/tcp-service.cfg.erb'),
            # restart to pick up new config files in conf.d
            notify  => Service['haproxy'],
        }
    } else {
        fail("Unknown service type ${type}")
    }

    $frontends.each | Integer $index, CloudLB::HAProxy::Service::Frontend $frontend | {
        if $firewall['restricted_to_fqdns'] {
            $srange = $firewall['restricted_to_fqdns']
            $src_sets = undef
        } elsif $firewall['open_to_cloud_private'] {
            $srange = undef
            $src_sets = ['CLOUD_PRIVATE_NETWORKS']
        } elsif $firewall['open_to_internet'] {
            $srange = undef
            $src_sets = undef
        } else {
            $srange = undef
            $src_sets = ['PRODUCTION_NETWORKS', 'LABS_NETWORKS']
        }

        $port = $frontend['port']

        firewall::service { "${title}_${port}":
            ensure   => present,
            proto    => 'tcp',
            port     => $port,
            srange   => $srange,
            src_sets => $src_sets,
        }
    }
}
