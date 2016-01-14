# == Class: role::piwik
#
# piwik is an open-source analytics platform.
# It powers <https://piwik.wikimedia.org>.
#
# Q: Why is there no piwik module?
# A: The only sanctioned way of configuring Piwik is via the web
#    installer. It is possible to provision a config.ini.php via Puppet,
#    but then you can't get to the web installer, so you are left with
#    no way to initialize the database, short of doing a bulk MySQL
#    import of a dump of an already-initialized Piwik database.
#
#    See #1586: Headless install / command line piwik remote install
#    <https://github.com/piwik/piwik/issues/1586>.
#    Closed with "We have implemented this plugin for Piwik PRO, please
#    get in touch if you are interested."
#
# Q: So where are the credentials?
# A: In pwstore.
#
# Q: Where did the package come from?
# A: http://debian.piwik.org/, imported to jessie-wikimedia.
#
class role::piwik {
    include ::apache::mod::authnz_ldap
    include ::apache::mod::headers
    include ::apache::mod::php5
    include ::apache::mod::rewrite

    include ::passwords::ldap::production
    include ::base::firewall

    require_package('piwik')
    require_package('mysql-server')

    system::role { 'role::piwik':
        description => 'Analytics piwik server',
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
    }

    monitoring::service { 'piwik':
        description   => 'piwik.wikimedia.org',
        check_command => 'check_http_url!piwik.wikimedia.org!/',
    }
}
