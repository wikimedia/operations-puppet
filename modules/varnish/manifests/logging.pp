# == Class varnish::logging
#
# This class sets up analytics/logging needed by cache servers
#
# === Parameters
#
# [*default_mtail_programs*]
#   The list of mtail programs to install.
#
# [*internal_mtail_programs*]
#   The list of internal mtail programs to install.
#
class varnish::logging(
    Array[String] $default_mtail_programs,
    Array[String] $internal_mtail_programs,
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

    # Common wrapper used by all varnishmtail instances
    file { '/usr/local/bin/varnishmtail-wrapper':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/varnish/varnishmtail-wrapper.sh',
    }

    # Remove internal scripts from default instance
    $internal_mtail_programs.each |String $name| {
        file { "/etc/mtail/${name}.mtail":
            ensure => absent,
            notify => Systemd::Service['varnishmtail@default'],
        }
    }

    varnish::logging::mtail { 'default':
        mtail_programs => $default_mtail_programs,
        mtail_port     => 3903,
    }

    varnish::logging::mtail { 'internal':
        mtail_programs => $internal_mtail_programs,
        mtail_port     => 3913,
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
