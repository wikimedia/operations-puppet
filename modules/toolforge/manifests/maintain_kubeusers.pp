class toolforge::maintain_kubeusers(
    Stdlib::Fqdn $k8s_master,
) {
    # Not using require_package because of dependency cycle, see
    # https://gerrit.wikimedia.org/r/#/c/430539/
    package { 'python3-ldap3':
        ensure => present,
    }

    require_package('python3-yaml')

    file { '/usr/local/bin/maintain-kubeusers':
        # TODO: we don't want to lose the git history in this script
        source => 'puppet:///modules/toollabs/maintain-kubeusers.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    systemd::service { 'maintain-kubeusers':
        ensure  => present,
        # TODO: this template is sensitive of the rbac vs abac stuff
        content => systemd_template('maintain-kubeusers'),
    }
}
