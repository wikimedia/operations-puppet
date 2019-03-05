# == Class: profile::piwik::webserver
#
# Apache webserver instance configured with mpm-prefork and mod_php.
# This configuration should be improved with something more up to date like
# mpm-event and php-fpm/hhmv.
# Piwik has been rebranded to 'Matomo', but to avoid too many changes
# we are going to just keep the previous name.
#
class profile::piwik::webserver(
    $prometheus_nodes = hiera('prometheus_nodes')
){
    include ::profile::prometheus::apache_exporter

    class { '::passwords::ldap::production': }

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

    if os_version('debian >= stretch') {
        $php_module = 'php7.0'
        $php_ini = '/etc/php/7.0/apache2/php.ini'

        package { 'php7.0-mbstring':
            ensure => 'present',
        }
        package { 'php7.0-xml':
            ensure => 'present',
        }
    } else {
        $php_module = 'php5'
        $php_ini = '/etc/php5/apache2/php.ini'
    }

    package { "libapache2-mod-${php_module}":
        ensure => 'present',
    }

    class { '::httpd':
        modules => ['authnz_ldap', 'headers', $php_module, 'rewrite'],
        require => Package["libapache2-mod-${php_module}"],
    }

    class { '::httpd::mpm':
        mpm    => 'prefork',
        source => 'puppet:///modules/profile/piwik/mpm_prefork.conf',
    }

    httpd::site { 'piwik.wikimedia.org':
        content => template('profile/piwik/piwik.wikimedia.org.erb'),
    }

    monitoring::service { 'piwik':
        description   => 'piwik.wikimedia.org',
        check_command => 'check_http_unauthorized!piwik.wikimedia.org!/',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Piwik',
    }

    file_line { 'enable_php_opcache':
        line   => 'opcache.enable=1',
        match  => '^;?opcache.enable\s*\=',
        path   => $php_ini,
        notify => Class['::httpd'],
    }

    file_line { 'php_memory_limit':
        line   => 'memory_limit = 256M',
        match  => '^;?memory_limit\s*\=',
        path   => $php_ini,
        notify => Class['::httpd'],
    }

    ferm::service { 'piwik_http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHES',
    }
}
