define apt::pin (
    $pin,
    $priority,
    $package=$name,
    $ensure=present,
) {
    # Validate that $name does not already have a ".pref" suffix.
    if $name =~ /\.pref$/ {
        fail('$name must not have a ".pref" suffix.')
    }

    file { "/etc/apt/preferences.d/${name}.pref":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "Package: ${package}\nPin: ${pin}\nPin-Priority: ${priority}\n",
        notify  => Exec['apt-get update'],
    }
}
