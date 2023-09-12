class varnish::common(
    Float $log_slow_request_threshold = 60.0,
    Optional[Stdlib::Host] $logstash_host = undef,
    Optional[Stdlib::Port] $logstash_json_lines_port = undef,
) {
    # Python version
    $python_version = debian::codename() ? {
        'buster'    => '3.7',
        'bullseye'  => '3.9',
        'bookworm'  => '3.11',
    }

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

    # `vlogdump` is a small tool to filter the output of varnishlog
    # See <https://github.com/cosimo/vlogdump> for more.
    file { '/usr/local/bin/vlogdump':
        source => 'puppet:///modules/varnish/vlogdump',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    nrpe::plugin { 'check_varnish_uds':
        source => 'puppet:///modules/varnish/check_varnish_uds.py';
    }

}
