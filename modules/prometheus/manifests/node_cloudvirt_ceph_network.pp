class prometheus::node_cloudvirt_ceph_network (
    Wmflib::Ensure $ensure  = 'present',
) {
    $script = '/usr/local/bin/prometheus-cloudvirt-ceph-network'
    file { $script:
        ensure => $ensure,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-cloudvirt-ceph-network.py',
    }

    systemd::timer::job { 'prometheus-node-cloudvirt-ceph-network':
        ensure      => $ensure,
        user        => 'root',
        description => 'Generate prometheus node metrics for cloudvirt ceph network usage',
        command     => $script,
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => 'minutely',
        },
        require     => [File[$script], Class['prometheus::node_exporter'],]
    }
}
