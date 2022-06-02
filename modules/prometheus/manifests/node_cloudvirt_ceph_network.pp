class prometheus::node_cloudvirt_ceph_network (
    Wmflib::Ensure $ensure  = 'present',
) {
    $nodelist_file = '/etc/prometheus-cloudvirt-ceph-network-nodelist.txt'
    $nodes = sort(wmflib::role::hosts('wmcs::ceph::osd') + wmflib::role::hosts('wmcs::ceph::mon')).unique
    file { $nodelist_file:
        ensure  => $ensure,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => inline_template("<% @nodes.each do |n| -%><%= scope.function_ipresolve([n]) %>\n<% end -%>\n"),
    }

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
        require     => [File[$script], Class['prometheus::node_exporter'], File[$nodelist_file]]
    }
}
