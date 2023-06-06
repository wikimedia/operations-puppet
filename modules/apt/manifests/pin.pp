define apt::pin (
    String         $pin,
    Integer        $priority,
    String         $package       = $name,
    Wmflib::Ensure $ensure        = present,
) {
    include apt
    # Braces required on puppet < 5.4 PUP-8067
    $filename = ($name =~ /\.pref$/) ? {
        true    => $name.regsubst('[^\w\.]', '_', 'G'),
        default => "${name.regsubst('\W', '_', 'G')}.pref",
    }

    # We intentionally don't use the exec defined in the apt class to avoid
    # dependency cycles. We require the apt class to be applied before any
    # packages are installed, so we don't want to also require this define to be
    # applied before the apt class as we may need to install a package before
    # this define.
    exec {"apt_pin_${title}":
        command     => '/usr/bin/apt-get update',
        refreshonly => true,
    }

    $_notify = defined('$notify') ? {
        true => $notify,
        default => Exec["apt_pin_${title}"],
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
