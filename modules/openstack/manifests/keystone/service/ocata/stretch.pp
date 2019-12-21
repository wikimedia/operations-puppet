class openstack::keystone::service::ocata::stretch(
) {
    require ::openstack::serverpackages::ocata::stretch

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

    # pull in python-ldap version 3+ from the buster repo.
    #  older versions don't handle unicode properly.
    #  T229227
    apt::repository { 'stretch-wikimedia-component-python-ldap-bpo':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => stretch-wikimedia,
        components => 'component/python-ldap-bpo',
        before     => Package['keystone'],
        notify     => Exec['apt_update_python_ldap'],
    }
    exec {'apt_update_python_ldap':
        command     => '/usr/bin/apt-get update',
        refreshonly => true,
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

    package { $packages:
        ensure  => 'present',
    }
}
