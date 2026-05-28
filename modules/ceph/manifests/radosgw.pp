# SPDX-License-Identifier: Apache-2.0
class ceph::radosgw {
    if defined(Ceph::Auth::Keyring['radosgw']) {
        Ceph::Auth::Keyring['radosgw'] -> Class['ceph::radosgw']
    }
    ensure_packages('radosgw')

    service { 'ceph-radosgw@radosgw':
        ensure    => running,
        enable    => true,
        subscribe => File['/etc/ceph/ceph.conf'],
    }

    systemd::syslog { 'radosgw':
        force_stop   => true,
        base_dir     => '/var/log/ceph',
        owner        => 'ceph',
        group        => 'ceph',
        readable_by  => 'group',
        log_filename => 'radosgw.log',
        require      => Package['radosgw'],
    }

    file { '/usr/local/bin/prometheus-export-radosgw-stats':
        ensure => present,
        mode   => '0555',
        source => 'puppet:///modules/ceph/export_radosgw_metrics.py'
    }

    prometheus::node_textfile { 'prometheus-export-radosgw-metrics':
        ensure         => 'present',
        interval       => '*-*-* *:00,30', # at min 0 and 30, aka every 30 minutes
        run_cmd        => '/usr/local/bin/prometheus-export-radosgw-stats --outfile /var/lib/prometheus/node.d/radosgw.prom',
        extra_packages => ['python3-prometheus-client'],
    }
}
