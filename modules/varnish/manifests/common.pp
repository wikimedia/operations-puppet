class varnish::common(
    Float $log_slow_request_threshold = 60.0,
    Optional[Stdlib::Host] $logstash_host = undef,
    Optional[Stdlib::Port] $logstash_json_lines_port = undef,
) {
    # Python version
    # TODO: use case for python_version fact
    $python_version = '3.7'

    file { '/usr/local/sbin/reload-vcl':
        source => 'puppet:///modules/varnish/reload-vcl.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    # Scripts to depool, restart and repool varnish frontends
    file { '/usr/local/sbin/varnish-frontend-restart':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/varnish/varnish-frontend-restart.sh',
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

    file { '/usr/local/lib/python2.7/dist-packages/varnishapi.py':
        ensure => absent,
    }

    file { '/usr/local/lib/python2.7/dist-packages/varnishlog.py':
        ensure => absent,
    }

    file { '/usr/local/lib/python2.7/dist-packages/cachestats.py':
        ensure => absent,
    }

    nrpe::plugin { 'check_varnish_uds':
        source => 'puppet:///modules/varnish/check_varnish_uds.py';
    }

    sudo::user { 'nagios_varnish_uds':
        ensure => absent,
    }
}
