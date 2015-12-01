# Ensures any varnish daemon instance with the given suffix (blank
# for default/unnamed) is stopped and unconfigured before any
# defined varnish::instance is configured and/or started.

define varnish::remove_instance() {
    require varnish::common

    $suffix = $title

    exec { "stop-varnish${suffix}":
        user    => 'root',
        path    => '/usr/sbin:/sbin:/usr/bin:/bin',
        command => "service varnish${suffix} stop",
        onlyif  => "service varnish${suffix} status",
    }

    $initfiles = [
        "/etc/init.d/varnish${suffix}",
        "/etc/systemd/system/varnish${suffix}.service",
        "/lib/systemd/system/varnish${suffix}.service",
    ]

    file { $initfiles:
        ensure  => absent,
        require => Exec["stop-varnish${suffix}"],
        notify  => Exec["systemctl-reload-vi${suffix}"],
    }

    exec { "systemctl-reload-vi${suffix}":
        user        => 'root',
        path        => '/usr/sbin:/sbin:/usr/bin:/bin',
        command     => 'systemctl daemon-reload',
        refreshonly => true,
    }

    Varnish::Remove_instance <| |> -> Varnish::Instance <| |>
}
