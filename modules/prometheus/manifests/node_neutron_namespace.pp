class prometheus::node_neutron_namespace (
    Wmflib::Ensure $ensure  = 'present',
) {
    $script = '/usr/local/bin/prometheus-neutron-namespace'
    file { $script:
        ensure => $ensure,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-neutron-namespace.py',
    }

    systemd::timer::job { 'prometheus-node-neutron-namespace':
        ensure      => $ensure,
        user        => 'root',
        description => 'Generate prometheus node metrics for conntrack in neutron namespaces',
        command     => $script,
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => 'minutely',
        },
        require     => [File[$script], Class['prometheus::node_exporter'],]
    }
}
