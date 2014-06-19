define apt::pin (
    $pin,
    $priority,
    $package=$name,
    $ensure=present,
) {
    file { "/etc/apt/preferences.d/${name}":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "Package: ${package}\nPin: ${pin}\nPin-Priority: ${priority}\n",
    }
}
