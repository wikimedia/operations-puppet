class openstack::keystone::service::mitaka::stretch(
) {
    require ::openstack::serverpackages::mitaka::stretch

    apt::repository { 'stretch-wikimedia-thirdparty-oath':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => stretch-wikimedia,
        components => 'thirdparty/oath',
        source     => false,
        before     => Package[python-oath],
    }

    package { 'python-oath':
        ensure  => present,
    }

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
    apt::pin { 'stretch_mitaka_pinning_python_routes':
        package  => 'python-routes',
        pin      => 'version 2.2-1~bpo8+1',
        priority => '1002',
    }

    # packages will be installed from openstack-mitaka-jessie component from
    # the jessie-wikimedia repo, since that has higher apt pinning by default
    package { $packages:
        ensure  => 'present',
        require => Apt::Pin[stretch_mitaka_pinning_python_routes],
    }
}
