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
    require_package(['prometheus-snmp-exporter', 'python3-yaml'])

    prometheus::snmp_exporter::module { 'default':
        template => 'default',
    }

    base::service_unit { 'prometheus-snmp-exporter':
        ensure    => present,
        refresh   => true,
        strict    => false,
        require   => Package['prometheus-snmp-exporter'],
        subscribe => Exec['prometheus-snmp-exporter-config'],
    }

    base::service_auto_restart { 'prometheus-snmp-exporter': }

    file { '/etc/prometheus/snmp.yml.d':
        ensure => directory,
        mode   => '0500',
        owner  => 'root',
        group  => 'root',
    }

    file { '/etc/prometheus/snmp.yml':
        ensure => present,
        mode   => '0400',
        owner  => 'prometheus',
        group  => 'root',
    }

    file { '/usr/local/bin/prometheus-snmp-exporter-config':
        ensure => present,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-snmp-exporter-config.py',
    }

    exec { 'prometheus-snmp-exporter-config':
        refreshonly => true,
        command     => '/usr/local/bin/prometheus-snmp-exporter-config',
        require     => File['/usr/local/bin/prometheus-snmp-exporter-config'],
    }
}
