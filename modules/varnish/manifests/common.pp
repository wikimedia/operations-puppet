class varnish::common {
    require varnish::packages

    # Tune kernel settings
    # TODO: Should be moved to a role class.
    include webserver::sysctl_settings

    # Mount /var/lib/ganglia as tmpfs to avoid Linux flushing mlocked
    # shm memory to disk
    mount { '/var/lib/varnish':
        ensure  => mounted,
        device  => 'tmpfs',
        fstype  => 'tmpfs',
        options => 'noatime,defaults,size=512M',
        pass    => 0,
        dump    => 0,
        require => Class['varnish::packages'],
    }

    file { '/usr/share/varnish/reload-vcl':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => "puppet:///modules/varnish/reload-vcl",
    }

    file { '/usr/share/varnish/vlogdump':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/varnish/vlogdump',
    }
}
