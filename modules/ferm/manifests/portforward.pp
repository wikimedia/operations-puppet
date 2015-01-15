define ferm::portforward(
    $proto,
    $sport,
    $dport,
    $dest,
    $ensure = 'present',
    $desc   = '',
    $prio   = '10',
) {
    @file { "/etc/ferm/conf.d/${prio}_${name}":
        ensure  => $ensure,
        owner   => root,
        group   => root,
        mode    => '0400',
        content => template('ferm/portforward.erb'),
        require => File['/etc/ferm/conf.d'],
        notify  => Service['ferm'],
        tag     => 'ferm',
    }
}
