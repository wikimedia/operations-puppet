class varnish::common {
    require varnish::packages

    if (hiera('varnish_version4', false)) {
        $varnish4_python_suffix = '4'
    } else {
        $varnish4_python_suffix = ''
    }

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

    # Script to depool, restart and repool a varnish backend
    file { '/usr/local/sbin/varnish-backend-restart':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/varnish/varnish-backend-restart',
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
        source  => "puppet:///modules/varnish/varnishprocessor${varnish4_python_suffix}",
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

    if (hiera('varnish_version4', false)) {
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
    } else {
        file { '/usr/local/lib/python2.7/dist-packages/varnishlog.py':
            source => 'puppet:///modules/varnish/varnishlog.py',
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
        }

        # We don't use varnishlog at all, and it can become an issue, see T135700
        service { 'varnishlog':
            ensure => 'stopped'
        }
    }
}
