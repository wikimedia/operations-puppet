class toollabs::maintain_kubeusers(
    $k8s_master,
) {

    # Not using require_package because of dependency cycle, see
    # https://gerrit.wikimedia.org/r/#/c/430539/
    package { 'python3-ldap3':
        ensure => present,
    }

    require_package('python3-yaml')

    file { '/usr/local/bin/maintain-kubeusers':
        source => 'puppet:///modules/toollabs/maintain-kubeusers',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    systemd::service { 'maintain-kubeusers':
        ensure  => present,
        content => systemd_template('maintain-kubeusers'),
    }
}
