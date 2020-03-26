class openstack::keystone::service::queens::stretch(
) {
    require ::openstack::serverpackages::queens::stretch

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
        'ldapvi',
        'python3-ldap3',
        'ruby-ldap',
        'python3-mwclient',
        'libapache2-mod-wsgi-py3',
    ]

    package { $packages:
        ensure  => 'present',
    }
}
