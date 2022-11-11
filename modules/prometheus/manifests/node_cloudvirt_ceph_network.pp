# this can be deleted
class prometheus::node_cloudvirt_ceph_network (
) {
    $nodelist_file = '/etc/prometheus-cloudvirt-ceph-network-nodelist.txt'
    file { $nodelist_file:
        ensure  => absent,
    }

    $script = '/usr/local/bin/prometheus-cloudvirt-ceph-network'
    file { $script:
        ensure => absent,
    }

    systemd::timer::job { 'prometheus-node-cloudvirt-ceph-network':
        ensure      => absent,
        user        => 'root',
        description => 'Generate prometheus node metrics for cloudvirt ceph network usage',
        command     => $script,
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => 'minutely',
        },
    }
}
