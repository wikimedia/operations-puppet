# SPDX-License-Identifier: Apache-2.0

class openstack::keystone::service::yoga::bullseye(
    Stdlib::Port $public_bind_port,
    Stdlib::Port $admin_bind_port,
) {
    require ::openstack::serverpackages::yoga::bullseye

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
    file { '/etc/init.d/keystone':
        mode    => '0755',
        content => template('openstack/yoga/keystone/keystone-public-service.erb'),
        require => Package['keystone'];
    }
    file { '/etc/init.d/keystone-admin':
        mode    => '0755',
        content => template('openstack/yoga/keystone/keystone-admin-service.erb'),
        require => Package['keystone'];
    }
    service {'keystone':
        ensure  => 'running',
        require => File['/etc/init.d/keystone'];
    }
    service {'keystone-admin':
        ensure  => 'running',
        require => File['/etc/init.d/keystone-admin'];
    }
}
