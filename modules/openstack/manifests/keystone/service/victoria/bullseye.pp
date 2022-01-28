class openstack::keystone::service::victoria::bullseye(
) {
    require ::openstack::serverpackages::victoria::bullseye

    $packages = [
        'keystone',
        'alembic',
        'ldapvi',
        'python3-ldappool',
        'python3-ldap3',
        'ruby-ldap',
        'python3-mwclient',
    ]

    package { $packages:
        ensure  => 'present',
    }

    # Temporary (?) time-out for apache + mod_wsgi which don't work with Keystone
    # on bullseye
    service {'keystone':
        ensure  => 'running',
        require => Package['keystone'];
    }
}
