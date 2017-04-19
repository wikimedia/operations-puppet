# == Class: profile::piwik::webserver
#
# Apache webserver instance configured with mpm-prefork and mod_php.
# This configuration should be improved with something more up to date like
# mpm-event and php-fpm/hhmv.
#
class profile::piwik::webserver {
    class { '::apache::mod::authnz_ldap' }
    class { '::apache::mod::headers' }
    class { '::apache::mod::php5' }
    class { '::apache::mod::rewrite' }

    class { '::passwords::ldap::production' }
    class { '::base::firewall' }

    # LDAP configuration. Interpolated into the Apache site template
    # to provide mod_authnz_ldap-based user authentication.
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

    class { '::apache::mpm':
        mpm    => 'prefork',
        source => 'puppet:///modules/profile/piwik/mpm_prefork.conf',
    }

    apache::site { 'piwik.wikimedia.org':
        content => template('profile/piwik/piwik.wikimedia.org.erb'),
    }

    monitoring::service { 'piwik':
        description   => 'piwik.wikimedia.org',
        check_command => 'check_http_unauthorized!piwik.wikimedia.org!/',
    }

    file_line { 'enable_php_opcache':
        line   => 'opcache.enable=1',
        match  => '^;?opcache.enable\s*\=',
        path   => '/etc/php5/apache2/php.ini',
        notify => Class['::apache'],
    }

    file_line { 'php_memory_limit':
        line   => 'memory_limit = 256M',
        match  => '^;?memory_limit\s*\=',
        path   => '/etc/php5/apache2/php.ini',
        notify => Class['::apache'],
    }

    ferm::service { 'piwik_http':
        proto => 'tcp',
        port  => '80',
    }
}