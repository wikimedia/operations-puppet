# SPDX-License-Identifier: Apache-2.0
class prometheus::node_openstack_prometheus_radosgw_quota_exporter (
    Wmflib::Ensure   $ensure      = 'present',
) {
    $script = '/usr/local/bin/prometheus-radosgw-quota-exporter'
    file { $script:
        ensure => stdlib::ensure($ensure, 'file'),
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus_radosgw_quota_exporter.py',
    }

    systemd::timer::job { 'prometheus-node-prometheus-radosgw-quota-exporter':
        ensure      => stdlib::ensure($ensure),
        user        => 'root',
        description => 'Generate prometheus metrics about the rados gw quota usage',
        command     => $script,
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => 'hourly',
        },
    }
}
