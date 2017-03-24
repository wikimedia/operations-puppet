class varnish::common {
    require ::varnish::packages

    # Mount /var/lib/varnish as tmpfs to avoid Linux flushing mlocked
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

    file { '/usr/local/share/dstat/dstat_varnish_hit.py':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/varnish/dstat_varnish_hit.py',
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
        ensure  => absent,
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
        ensure => 'stopped',
    }

    # varnishlog.py depends on varnishapi. Install it.
    file { '/usr/local/lib/python2.7/dist-packages/varnishapi.py':
        source => 'puppet:///modules/varnish/varnishapi.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    # Install varnishlog.py
    file { '/usr/local/lib/python2.7/dist-packages/varnishlog.py':
        source  => 'puppet:///modules/varnish/varnishlog.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File['/usr/local/lib/python2.7/dist-packages/varnishapi.py'],
    }

    # Install cachestats.py
    file { '/usr/local/lib/python2.7/dist-packages/cachestats.py':
        source => 'puppet:///modules/varnish/cachestats.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    # We have found a correlation between the 503 errors described in T145661
    # and the expiry thread not being able to catch up with its mailbox
    file { '/usr/local/lib/nagios/plugins/check_varnish_expiry_mailbox_lag':
        ensure => present,
        source => 'puppet:///modules/varnish/check_varnish_expiry_mailbox_lag.sh',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    nrpe::monitor_service { 'check_varnish_expiry_mailbox_lag':
        description    => 'Check Varnish expiry mailbox lag',
        nrpe_command   => '/usr/local/lib/nagios/plugins/check_varnish_expiry_mailbox_lag',
        retries        => 10,
        check_interval => 10,
        require        => File['/usr/local/lib/nagios/plugins/check_varnish_expiry_mailbox_lag'],
    }
}
