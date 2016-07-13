# == Class: role::xhgui::app
#
# XHGUI is a MongoDB-backed PHP webapp for viewing and analyzing
# PHP profiling data.
#
# Note that indexes on the MongoDB database on the target system
# need to be declared manually. The indexes (and commands to create
# them) are:
#
#  use xhprof;
#  # Retain profiles for 30 days:
#  db.results.ensureIndex( { 'meta.SERVER.REQUEST_TIME' : -1 },
#                          { expireAfterSeconds: 2592000 } );
#  db.results.ensureIndex( { 'meta.SERVER.REQUEST_TIME' : -1 } );
#  db.results.ensureIndex( { 'profile.main().wt' : -1 } );
#  db.results.ensureIndex( { 'profile.main().mu' : -1 } );
#  db.results.ensureIndex( { 'profile.main().cpu' : -1 } );
#  db.results.ensureIndex( { 'meta.url' : 1 } );
#
class role::xhgui::app {
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

    system::role { 'role::xhgui::app': }

    require_package('php5-mongo')

    file_line { 'set_php_memory_limit':
        path   => '/etc/php5/apache2/php.ini',
        match  => '^;?memory_limit\s*=',
        line   => 'memory_limit = 512M',
        notify => Class['::apache'],
    }

    file_line { 'enable_php_opcache':
        line   => 'opcache.enable=1',
        match  => '^;?opcache.enable\s*\=',
        path   => '/etc/php5/apache2/php.ini',
        notify => Class['::apache'],
    }

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

    git::clone { 'operations/software/xhprof':
        ensure    => 'latest',
        directory => '/srv/xhprof',
        branch    => 'wmf_deploy',
    } ->

    file { '/srv/xhprof/profiles':
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755',
    }

    git::clone { 'operations/software/xhgui':
        ensure    => 'latest',
        directory => '/srv/xhgui',
        branch    => 'wmf_deploy',
    } ->

    file { '/srv/xhgui/cache':
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755',
    } ->

    apache::site { 'xhgui_apache_site':
        content => template('apache/sites/xhgui.erb'),
    }
}
