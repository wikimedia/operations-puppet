define ferm::conf(
    $source,
    $ensure='present',
    $prio='10',
) {
    @file { "/etc/ferm/conf.d/${prio}_${name}":
        ensure  => $ensure,
        owner   => root,
        group   => root,
        mode    => '0400',
        source  => $source,
        require => File['/etc/ferm/conf.d'],
        notify  => Service['ferm'],
        tag     => 'ferm',
    }
}
