# SPDX-License-Identifier: Apache-2.0
#
# Assemble Prometheus-related config fragments.
# See prometheus::blackbox_exporter for an example usage.

class prometheus::assemble_config {
    # This class is used by pint, which can run with Thanos only
    # (i.e. Prometheus is not installed)
    if (!defined(File['/etc/prometheus'])) {
        file { '/etc/prometheus':
            ensure => directory,
            mode   => '0555',
            owner  => 'root',
            group  => 'root',
        }
    }

    file { '/usr/local/bin/prometheus-assemble-config':
        ensure => present,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/assemble_config.py',
    }

    file { '/etc/prometheus/assemble-config.yaml':
        ensure => present,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/assemble-config.yaml',
    }

    # Old file location
    file { '/usr/local/bin/blackbox-exporter-assemble':
        ensure => absent,
    }
}
