class varnish::common {
    require varnish::packages

    # Tune kernel settings
    # TODO: Should be moved to a role class.
    include webserver::base

    # Mount /var/lib/ganglia as tmpfs to avoid Linux flushing mlocked
    # shm memory to disk
    mount { "/var/lib/varnish":
        require => Class["varnish::packages"],
        device => "tmpfs",
        fstype => "tmpfs",
        options => "noatime,defaults,size=512M",
        pass => 0,
        dump => 0,
        ensure => mounted;
    }

    file {
        "/usr/share/varnish/reload-vcl":
            source => "puppet:///modules/${module_name}/reload-vcl",
            mode => 0555;
    }
}
