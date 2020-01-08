define apt::pin (
    $pin,
    $priority,
    $package=$name,
    $ensure=present,
) {
    $filename = $name =~ /\.pref$/ ? {
        true    => $name,
        default => "${name.regsubst('\W', '_', 'G')}.pref"
    }

    $_notify = defined('$notify') ? {
        true => $notify,
        default => Exec['apt-get update'],
    }

    file { "/etc/apt/preferences.d/${filename}":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "Package: ${package}\nPin: ${pin}\nPin-Priority: ${priority}\n",
        notify  => $_notify,
    }
}
