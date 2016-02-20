# == Class: role::xhgui
#
# XHGUI is a MongoDB-backed PHP webapp for viewing and analyzing
# PHP profiling data.
#
class role::xhgui {
    include ::apache::mod::authnz_ldap
    include ::apache::mod::php5
    include ::apache::mod::rewrite

    include ::mongodb

    include ::passwords::ldap::production


    $auth_ldap = {
        name          => 'nda/ops/wmf',
        bind_dn       => 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org',
        bind_password => $passwords::ldap::production::proxypass,
        url           => 'ldaps://ldap-labs.eqiad.wikimedia.org ldap-labs.codfw.wikimedia.org/ou=people,dc=wikimedia,dc=org?cn',
        groups        => [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
            'cn=nda,ou=groups,dc=wikimedia,dc=org',
            'cn=wmf,ou=groups,dc=wikimedia,dc=org',
        ],
    }

    system::role { 'role::xhgui': }

    require_package('php5-mongo')

    ferm::service { 'xhgui_mongodb':
        port   => 27017,
        proto  => 'tcp',
        srange => '$INTERNAL',
    }

    ferm::service { 'xhgui_http':
        port   => 80,
        proto  => 'tcp',
        srange => '$INTERNAL',
    }

    git::clone { 'operations/software/xhgui':
        ensure    => 'latest',
        directory => '/srv/xhgui',
        branch    => 'wmf_deploy',
    } ->

    file { '/srv/xhgui/cache':
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0755',
    } ->

    apache::site { 'xhgui_apache_site':
        content => template('apache/sites/xhgui.erb'),
    }
}
