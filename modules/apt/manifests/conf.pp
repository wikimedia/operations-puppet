define apt::conf(
    $key,
    $value,
    $priority='20',
    $ensure=present,
) {
    file { "/etc/apt/apt.conf.d/${priority}${name}":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "${key} \"${value}\";\n",
    }
}
