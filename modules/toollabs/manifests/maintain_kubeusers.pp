class toollabs::maintain_kubeusers(
    $k8s_master,
) {
    file { '/usr/local/bin/maintain-kubeusers':
        source => 'puppet:///modules/toollabs/maintain-kubeusers',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    sudo::user { 'restart_kube_apiserver':
        ensure     => present,
        user       => 'kubernetes',
        privileges => [ 'ALL = (root) NOPASSWD: /bin/systemctl restart kube-apiserver' ],
    }

    base::service_unit { 'maintain-kubeusers':
        systemd => True,
        require => Sudo::User['restart_kube_apiserver'],
    }
}