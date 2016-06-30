class toollabs::maintain_kubeusers(
    $k8s_master,
) {
    file { '/usr/local/bin/maintain-kubeusers':
        source => 'puppet:///modules/toollabs/maintain-kubeusers',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    base::service_unit { 'maintain-kubeusers':
        ensure  => absent,
        systemd => True,
    }
}