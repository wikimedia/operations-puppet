define ferm::conf(
    $source  = undef,
    $content = undef,
    $ensure  = present,
    $prio    = 10,
) {
    if $source == undef and $content == undef {
        fail('Either source or content attribute needs to be given')
    }
    if $source != undef and $content != undef {
        fail('Both source and content attribute have been defined')
    }
    @file { "/etc/ferm/conf.d/${prio}_${name}":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        source  => $source,
        content => $content,
        require => File['/etc/ferm/conf.d'],
        notify  => Service['ferm'],
        tag     => 'ferm',
    }
}
