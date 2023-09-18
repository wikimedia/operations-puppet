# == Class: prometheus::snmp_exporter
#
# The SNMP exporter provides an HTTP endpoint to poll SNMP devices
# and transform the result into Prometheus metrics.
#
# The transformation is driven by 'modules' instructing snmp_exporter which
# OIDs to poll and how to construct metrics from received OIDs.
#
# Additional modules can be added with prometheus::snmp_exporter::module and
# queried via HTTP by using 'module=<name>' on the query string.

class prometheus::snmp_exporter {
    ensure_packages(['prometheus-snmp-exporter'])

    require prometheus::assemble_config

    prometheus::snmp_exporter::module { 'default':
        template => 'default',
    }

    service { 'prometheus-snmp-exporter':
        ensure  => running,
        require => Package['prometheus-snmp-exporter'],
    }

    profile::auto_restarts::service { 'prometheus-snmp-exporter': }

    file { '/etc/prometheus/snmp.yml.d':
        ensure => directory,
        mode   => '0500',
        owner  => 'root',
        group  => 'root',
    }

    file { '/usr/local/bin/prometheus-snmp-exporter-config':
        ensure => absent,
    }

    exec { 'assemble snmp.yml':
        onlyif  => 'prometheus-assemble-config --onlyif snmp',
        command => 'prometheus-assemble-config snmp',
        notify  => Service['prometheus-snmp-exporter'],
        path    => '/usr/local/bin',
    }
}
