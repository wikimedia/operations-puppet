class dnsrecursor::metalresolver(
    $metal_resolver,
    $tld,
) {
    $labs_metal = hiera('labs_metal',[])

    file { $metal_resolver:
        ensure  => present,
        require => Package['pdns-recursor'],
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['pdns-recursor'],
        content => template('dnsrecursor/metaldns.lua.erb'),
    }
}
