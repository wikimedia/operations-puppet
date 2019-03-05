# == Class: profile::webperf::xhgui
#
# This class is still a work in progress!
# See https://phabricator.wikimedia.org/T180761.
#
# Provision XHGui, a graphical interface for XHProf data
# built on MongoDB. Used by the Performance Team.
#
# See also profile::webperf::site, which provisions a proxy
# to expose the service at <https://performance.wikimedia.org/xhgui/>.
#
class profile::webperf::xhgui {

    require_package('libapache2-mod-php7.0', 'php-mongodb')

    ferm::service { 'webperf-xhgui-http':
        proto  => 'tcp',
        port   => '80',
        srange => '$INTERNAL',
    }

    ferm::service { 'webperf-xhgui-mongo':
        proto  => 'tcp',
        port   => '27017',
        srange => '$INTERNAL',
    }

    class { '::mongodb': }

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
