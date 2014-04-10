define diamond::collector(
    $ensure = 'present',
    $config = undef,
) {
    file { "/etc/diamond/collectors/${name}.conf":
        ensure     => $ensure,
        content    => $config,
        subscribe  => Package['diamond'],
        notify     => Service['diamond'],
    }
}
