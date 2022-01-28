class openstack::keystone::service::victoria::buster(
    Stdlib::Port $public_bind_port,
    Stdlib::Port $admin_bind_port,
) {
    require ::openstack::serverpackages::victoria::buster

    $packages = [
        'keystone',
        'alembic',
        'python-alembic',
        'python-amqp',
        'python-castellan',
        'python-cliff',
        'python-cmd2',
        'python-concurrent.futures',
        'python-cryptography',
        'python-dogpile.cache',
        'python-eventlet',
        'python-funcsigs',
        'python-futurist',
        'python-jinja2',
        'python-jsonschema',
        'python-kombu',
        'python-memcache',
        'python-migrate',
        'python-openssl',
        'python-pyasn1',
        'python-pyinotify',
        'python-pymysql',
        'python-pyparsing',
        'python-routes',
        'python-sqlalchemy',
        'python-unicodecsv',
        'python-warlock',
        'ldapvi',
        'python-ldap',
        'python3-ldappool',
        'python3-ldap3',
        'ruby-ldap',
        'python3-mwclient',
        'libapache2-mod-wsgi-py3',
    ]

    package { $packages:
        ensure  => 'present',
    }

    # Keystone is managed via apache/wsgi on buster so we don't
    #  want the systemd unit running.
    exec { 'mask_keystone_service':
        command => '/bin/systemctl mask keystone.service',
        creates => '/etc/systemd/system/keystone.service',
        require => Package['keystone'];
    }
    service {'keystone':
        ensure  => 'stopped',
        require => Package['keystone'];
    }
}
