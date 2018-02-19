class toollabs::maintain_kubeusers(
    $k8s_master,
) {

    # We need a newer version of python3-ldap3 than what is in Jessie
    # For the connection time out / server pool features
    apt::pin { [
        'python3-ldap3',
        'python3-pyasn1',
    ]:
        pin      => 'release a=jessie-backports',
        priority => '1001',
        before   => Package['python3-ldap3'],
    }

    require_package('python3-ldap3')

    file { '/usr/local/bin/maintain-kubeusers':
        source => 'puppet:///modules/toollabs/maintain-kubeusers',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    base::service_unit { 'maintain-kubeusers':
        ensure  => present,
        systemd => systemd_template('maintain-kubeusers'),
    }
}
