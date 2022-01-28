class openstack::keystone::service::victoria::bullseye(
    Stdlib::Port $public_bind_port,
    Stdlib::Port $admin_bind_port,
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
    file { '/etc/default/keystone':
        owner   => 'keystone',
        group   => 'keystone',
        mode    => '0555',
        content => template('openstack/victoria/keystone/bullseye/default.erb'),
        notify  => Service['keystone'],
    }
    service {'keystone':
        ensure  => 'running',
        require => Package['keystone'];
    }
}
