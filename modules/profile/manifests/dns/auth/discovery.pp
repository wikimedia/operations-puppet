# SPDX-License-Identifier: Apache-2.0
# DNS Service Discovery Config
class profile::dns::auth::discovery(
    String $conftool_prefix = lookup('conftool_prefix'),
) {
    # Create a list of all available discovery services.
    $discovery_services = wmflib::service::get_services_for('discovery')
        .map|$n, $svc| { $svc['discovery'].map |$record| {$record + {'ip' => $svc['ip']}}}
        .flatten()
        .unique()

    file { '/etc/gdnsd/discovery-geo-resources':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/dns/auth/discovery-geo-resources.erb'),
        notify  => Service['gdnsd'],
        before  => Exec['authdns-local-update'],
    }

    file { '/etc/gdnsd/discovery-metafo-resources':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/dns/auth/discovery-metafo-resources.erb'),
        notify  => Service['gdnsd'],
        before  => Exec['authdns-local-update'],
    }

    file { '/etc/gdnsd/discovery-states':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/dns/auth/discovery-states.erb'),
        notify  => Service['gdnsd'],
        before  => Exec['authdns-local-update'],
    }

    file { '/etc/gdnsd/discovery-map':
        ensure => 'present',
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/profile/dns/auth/discovery-map',
        notify => Service['gdnsd'],
        before => Exec['authdns-local-update'],
    }

    file { '/usr/local/bin/authdns-check-active-passive':
        ensure => 'present',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/profile/dns/auth/authdns-check-active-passive',
    }

    class { 'confd':
        prefix  => $conftool_prefix,
        srv_dns => "${::site}.wmnet",
    }

    $discovery_services.each |$svc_data| {
        $keyspace = '/discovery'
        $svc_name = $svc_data['dnsdisc']
        $check = $svc_data['active_active'] ? {
            false => '/usr/local/bin/authdns-check-active-passive',
            true  => undef,
        }
        confd::file { "/var/lib/gdnsd/discovery-${svc_name}.state":
            uid        => '0',
            gid        => '0',
            mode       => '0444',
            content    => template('profile/dns/auth/discovery-statefile.tpl.erb'),
            watch_keys => ["${keyspace}/${svc_name}"],
            check      => $check,
        }
    }
}
