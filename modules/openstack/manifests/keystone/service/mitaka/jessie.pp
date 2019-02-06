class openstack::keystone::service::mitaka::jessie(
) {
    require ::openstack::serverpackages::mitaka::jessie

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
        'python-oath',
        'python-kombu',
        'python-mysql.connector',
        'python-memcache',
        'python-migrate',
        'python-openssl',
        'python-pyasn1',
        'python-pycadf',
        'python-pyinotify',
        'python-pymysql',
        'python-pyparsing',
        'python-routes',
        'python-sqlalchemy',
        'python-unicodecsv',
        'python-warlock',
        'ldapvi',
        'python-ldap',
        'python-ldappool',
        'python3-ldap3',
        'ruby-ldap',
        'python-mwclient',
    ]

    # bug: keystone requires this version of python-routes, but there are
    # no versioned depends of the package itself
    apt::pin { 'jessie_mitaka_pinning_python_routes':
        package  => 'python-routes',
        pin      => 'version 2.2-1~bpo8+1',
        priority => '1002',
    }

    package { $packages:
        ensure          => 'present',
        install_options => ['-t', 'jessie-backports'],
    }

    file {'/etc/keystone/original':
        ensure  => 'directory',
        owner   => 'keystone',
        group   => 'keystone',
        mode    => '0755',
        recurse => true,
        source  => 'puppet:///modules/openstack/mitaka/keystone/original',
        require => Package['keystone'],
    }
}
