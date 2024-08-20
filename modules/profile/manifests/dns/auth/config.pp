# SPDX-License-Identifier: Apache-2.0
class profile::dns::auth::config(
    Hash[String, Hash[String, Any]] $authdns_addrs = lookup('authdns_addrs'),
) {
    include ::network::constants
    include ::profile::firewall

    # Create the loopback IPs used for public service (defined here since we
    # also create the matching listener config here)
    # Skip loopbacks if bird sets up the loopbacks in a given site.
    $authdns_addrs.each |$alabel,$adata| {
        unless $adata['skip_loopback'] or $adata['skip_loopback_site'] == $::site {
            interface::ip { $alabel:
                address   => $adata['address'],
                interface => 'lo',
            }
        }
    }

    $service_listeners = $authdns_addrs.map |$aspec| { $aspec[1]['address'] }

    ferm::service { 'udp_dns_auth':
        proto   => 'udp',
        notrack => true,
        prio    => 5,
        port    => '53',
        drange  => "(${service_listeners.join(' ')})",
    }

    ferm::service { 'tcp_dns_auth':
        proto   => 'tcp',
        notrack => true,
        prio    => 5,
        port    => '53',
        drange  => "(${service_listeners.join(' ')})",
    }

    $monitor_listeners = [
        # Any-address, both protocols, port 5353, for blended-role monitoring
        '0.0.0.0:5353',
        '[::]:5353',
    ]

    file { '/etc/gdnsd':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/etc/gdnsd/config-options':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/dns/auth/config-options.erb'),
        require => File['/etc/gdnsd'],
        notify  => Service['gdnsd'],
        before  => Exec['authdns-local-update'],
    }
    file { '/etc/gdnsd/zones':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        before => Exec['authdns-local-update'],
    }

    require ::geoip::data::puppet
    file { '/etc/gdnsd/geoip':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    # This is a file copy rather than a softlink, so that gdnsd's ev_stat
    # watcher can notice changes to it.
    file { '/etc/gdnsd/geoip/GeoIP2-City.mmdb':
        ensure => 'present',
        backup => false,
        source => '/usr/share/GeoIP/GeoIP2-City.mmdb',
        before => Exec['authdns-local-update'],
    }

    file { '/etc/gdnsd/secrets':
        ensure => 'directory',
        owner  => 'gdnsd',
        group  => 'gdnsd',
        mode   => '0500',
    }
    file { '/etc/gdnsd/secrets/dnscookies.key':
        ensure    => 'present',
        owner     => 'gdnsd',
        group     => 'gdnsd',
        mode      => '0400',
        content   => wmflib::secret('dns/dnscookies.key', true),
        show_diff => false,
        notify    => Service['gdnsd'],
        before    => Exec['authdns-local-update'],
    }
}
