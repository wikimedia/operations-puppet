# SPDX-License-Identifier: Apache-2.0

class openstack::keystone::service::flamingo::trixie(
    Stdlib::Port $public_bind_port,
    Stdlib::Port $admin_bind_port,
) {
    $packages = [
        'keystone',
        'alembic',
        'ldapvi',
        'python3-ldappool',
        'python3-ldap3',
        'ruby-net-ldap',
        'python3-mwclient',
    ]

    ensure_packages($packages)

    # Temporary (?) time-out for apache + mod_wsgi which didn't work with Keystone
    # on bookworm
    file { '/etc/init.d/keystone':
        mode    => '0755',
        content => template('openstack/flamingo/keystone/keystone-public-service.erb'),
        require => Package['keystone'];
    }
    service {'keystone':
        ensure  => 'running',
        require => File['/etc/init.d/keystone'],
    }
}
