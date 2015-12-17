class dnsrecursor::metalresolver {

    $labs_metal = hiera('labs_metal',[])

    file { "/etc/powerdns/metaldns.lua:
        ensure  => present,
        require => Package['pdns-recursor'],
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['pdns-recursor'],
        content => template('dnsrecursor/metaldns.lua.erb'),
    }
}
