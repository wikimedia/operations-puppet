class profile::dns::auth::config(
    Hash[String, Hash[String, String]] $authdns_addrs = lookup('authdns_addrs'),
) {
    # Create the loopback IPs used for public service (defined here since we
    # also create the matching listener config here)
    create_resources(
        interface::ip,
        $authdns_addrs,
        { interface => 'lo', prefixlen => '32' }
    )

    $service_listeners = $authdns_addrs.map |$aspec| { $aspec[1]['address'] }

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
    file { '/etc/gdnsd/geoip/GeoIP2-City.mmdb':
        ensure => 'link',
        target => '/usr/share/GeoIP/GeoIP2-City.mmdb',
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
        content   => secret('dns/dnscookies.key'),
        show_diff => false,
        notify    => Service['gdnsd'],
        before    => Exec['authdns-local-update'],
    }
}
