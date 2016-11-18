class varnish::common {
    require varnish::packages

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

    # Scripts to depool, restart and repool varnish backends and frontends
    file { '/usr/local/sbin/varnish-backend-restart':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/varnish/varnish-backend-restart',
    }

    file { '/usr/local/sbin/varnish-frontend-restart':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/varnish/varnish-frontend-restart',
    }

    file { '/usr/local/share/dstat':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/usr/local/share/dstat/dstat_varnishstat.py':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/varnish/dstat_varnishstat.py',
        require => File['/usr/local/share/dstat'],
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
        source  => 'puppet:///modules/varnish/varnishprocessor4',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        recurse => true,
        purge   => true,
        force   => true,
    }

    # We are not using varnishncsa, make sure it's stopped
    service { 'varnishncsa':
        ensure => 'stopped',
        enable => false,
    }

    # We don't use varnishlog at all, and it can become an issue, see T135700
    service { 'varnishlog':
        ensure => 'stopped'
    }

    # varnishlog4.py depends on varnishapi. Install it.
    file { '/usr/local/lib/python2.7/dist-packages/varnishapi.py':
        source => 'puppet:///modules/varnish/varnishapi.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    # Install varnishlog4.py, compatible with Varnish 4
    file { '/usr/local/lib/python2.7/dist-packages/varnishlog.py':
        source  => 'puppet:///modules/varnish/varnishlog4.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File['/usr/local/lib/python2.7/dist-packages/varnishapi.py'],
    }
}
