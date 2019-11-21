# == Class: role::xhgui::app
#
# This class provisions XHGui with Apache and PHP
# and assumes no other web services use Apaache on the same host.
# It is being replaced by role::webperf::profiling_tools and
# profile::webperf::xhgui.
#
# -------
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

    if os_version('debian == buster') {
        $mongo_driver='php-mongodb'
        $httpd_php='php7.3'
        $php_ini='/etc/php/7.3/fpm/php.ini'
    } elsif os_version('debian == stretch') {
        $mongo_driver='php-mongodb'
        $httpd_php='php7.0'
        $php_ini='/etc/php/7.0/fpm/php.ini'
    } else {
        $mongo_driver='php5-mongo'
        $httpd_php='php5'
        $php_ini='/etc/php5/apache2/php.ini'
    }

    class { '::httpd':
        modules => ['authnz_ldap', $httpd_php, 'rewrite'],
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::mongodb
    include ::passwords::ldap::production

    $auth_ldap = {
        name          => 'nda/ops/wmf',
        bind_dn       => 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org',
        bind_password => $passwords::ldap::production::proxypass,
        url           => 'ldaps://ldap-ro.eqiad.wikimedia.org ldap-ro.codfw.wikimedia.org/ou=people,dc=wikimedia,dc=org?cn',
        groups        => [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
            'cn=nda,ou=groups,dc=wikimedia,dc=org',
            'cn=wmf,ou=groups,dc=wikimedia,dc=org',
        ],
    }

    system::role { 'xhgui::app': }

    require_package($mongo_driver)

    file_line { 'set_php_memory_limit':
        path   => $php_ini,
        match  => '^;?memory_limit\s*=',
        line   => 'memory_limit = 512M',
        notify => Class['::httpd'],
    }

    file_line { 'enable_php_opcache':
        line   => 'opcache.enable=1',
        match  => '^;?opcache.enable\s*\=',
        path   => $php_ini,
        notify => Class['::httpd'],
    }

    ferm::service { 'xhgui_mongodb':
        port   => 27017,
        proto  => 'tcp',
        srange => '$DOMAIN_NETWORKS',
    }

    ferm::service { 'xhgui_http':
        port   => 80,
        proto  => 'tcp',
        srange => '$DOMAIN_NETWORKS',
    }

    git::clone { 'operations/software/xhgui':
        ensure    => 'latest',
        directory => '/srv/xhgui',
        branch    => 'wmf_deploy',
    }
    -> file { '/srv/xhgui/cache':
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755',
    }
    -> httpd::site { 'xhgui_apache_site':
        content => template('profile/webperf/xhgui/httpd.conf.erb'),
    }
}
