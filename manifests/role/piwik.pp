# == Class: role::piwik
#
# piwik is an open-source analytics platform.
# It powers <https://piwik.wikimedia.org>.
#
class role::piwik {
    include ::apache::mod::authnz_ldap
    include ::apache::mod::headers
    include ::apache::mod::php5
    include ::apache::mod::rewrite

    include ::passwords::piwik
    include ::passwords::ldap::production

    include base::firewall

    class { '::piwik':
        settings => {
            database => {
                host          => 'FIXME',
                username      => $paswords::piwik::db_user,
                password      => $paswords::piwik::db_pass,
                dbname        => 'FIXME',
                tables_prefix => 'FIXME',
                port          => 3306,
                adapter       => 'PDO\MYSQL',
                type          => 'InnoDB',
                schema        => 'Mysql',
                charset       => 'utf8',
            }
        }
    }

    ferm::service { 'piwik_http':
        proto => 'tcp',
        port  => '80',
    }

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

    apache::site { 'piwik.wikimedia.org':
        content => template('apache/sites/piwik.wikimedia.org.erb'),
        require => Class['::piwik'],
    }

    monitoring::service { 'piwik':
        description   => 'piwik.wikimedia.org',
        check_command => 'check_http_url!piwik.wikimedia.org!/',
    }
}
