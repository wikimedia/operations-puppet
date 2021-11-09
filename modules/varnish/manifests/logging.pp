# == Class varnish::logging
#
# This class sets up analytics/logging needed by cache servers
#
# === Parameters
#
# [*mtail_programs*]
#   The list of mtail programs to install. Defaults to [].
#
class varnish::logging(
    $mtail_programs=[],
){
    ensure_packages('python3-logstash')

    rsyslog::conf { 'varnish':
        ensure   => absent,
        priority => 80,
    }

    rsyslog::conf { 'varnish_pipeline':
        content  => template('varnish/rsyslog.conf.erb'),
        priority => 20,
    }

    exec { 'mask_default_mtail':
        command => '/bin/systemctl mask mtail.service',
        creates => '/etc/systemd/system/mtail.service',
    }

    file { '/usr/local/bin/varnishmtail-default':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/varnish/varnishmtail-default.sh',
        notify => Systemd::Service['varnishmtail@default'],
    }

    file { '/etc/default/varnishmtail':
        ensure => absent,
    }

    systemd::service { 'varnishmtail@default':
        ensure  => present,
        content => systemd_template('varnishmtail@'),
        restart => true,
        require => File['/usr/local/bin/varnishmtail-default'],
    }

    $mtail_programs.each |String $name| {
        mtail::program { $name:
            source => "puppet:///modules/mtail/programs/${name}.mtail",
            notify => Systemd::Service['varnishmtail@default'],
        }
    }

    file { "/usr/local/lib/python${::varnish::common::python_version}/dist-packages/wikimedia_varnishlogconsumer.py":
        source => 'puppet:///modules/varnish/wikimedia_varnishlogconsumer.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file { '/usr/local/bin/varnishslowlog':
        source => 'puppet:///modules/varnish/varnishslowlog.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/usr/local/bin/varnishospital':
        source => 'puppet:///modules/varnish/varnishospital.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/usr/local/bin/varnishfetcherr':
        source => 'puppet:///modules/varnish/varnishfetcherr.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/usr/local/bin/varnishtlsinspector':
        source => 'puppet:///modules/varnish/varnishtlsinspector.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    systemd::service { 'varnish-frontend-tlsinspector':
        ensure         => absent,
        content        => systemd_template('varnishtlsinspector'),
        restart        => true,
        service_params => {
            require => Service['varnish-frontend'],
            enable  => false,
        },
        subscribe      => [
            File['/usr/local/bin/varnishtlsinspector'],
            File["/usr/local/lib/python${::varnish::common::python_version}/dist-packages/wikimedia_varnishlogconsumer.py"],
        ]
    }
}
