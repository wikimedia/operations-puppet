# == Class: role::piwik
#
# piwik is an open-source analytics platform.
# It powers <https://piwik.wikimedia.org>.
#
# Q: Why is there no piwik module?
# A: Piwik has no good configuration mechanism apart from the web installer.
#
class role::piwik {
    include ::apache::mod::authnz_ldap
    include ::apache::mod::headers
    include ::apache::mod::php5
    include ::apache::mod::rewrite

    include ::passwords::ldap::production
    include ::base::firewall

    require_package('piwik')

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
