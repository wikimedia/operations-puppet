class varnish::common {
    require varnish::packages

    # Tune kernel settings
    # TODO: Should be moved to a role class.
    include base::mysterious_sysctl

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
        source => 'puppet:///modules/varnish/reload-vcl',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    # `vlogdump` is a small tool to filter the output of varnishlog
    # See <https://github.com/cosimo/vlogdump> for more.
    file { '/usr/local/bin/vlogdump':
        source => 'puppet:///modules/varnish/vlogdump',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/usr/local/lib/python2.7/dist-packages/varnishprocessor':
        source  => 'puppet:///modules/varnish/varnishprocessor',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        recurse => true,
        purge   => true,
        force   => true,
    }

    file { '/usr/local/lib/python2.7/dist-packages/varnishlog.py':
        source => 'puppet:///modules/varnish/varnishlog.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
}
