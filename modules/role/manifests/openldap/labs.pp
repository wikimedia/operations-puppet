# LDAP servers for labs (based on OpenLDAP)

class role::openldap::labs {
    include passwords::openldap::labs
    include base::firewall

    system::role { 'role::openldap::labs':
        description => 'LDAP servers for labs (based on OpenLDAP)'
    }

    # Certificate needs to be readable by slapd
    sslcert::certificate { "ldap-labs.${::site}.wikimedia.org":
        group => 'openldap',
    }

    class { '::openldap':
        server_id   => 1,
        suffix      => 'dc=wikimedia,dc=org',
        datadir     => '/var/lib/ldap/labs',
        ca          => '/etc/ssl/certs/ca-certificates.crt',
        certificate => "/etc/ssl/localcerts/ldap-labs.${::site}.wikimedia.org.crt",
        key         => "/etc/ssl/private/ldap-labs.${::site}.wikimedia.org.key",
    }

    ferm::service { 'corp_ldap':
        proto  => 'tcp',
        port   => '389',
        srange => '(($INTERNAL @resolve(ldap-eqiad.wikimedia.org) @resolve(ldap-codfw.wikimedia.org)))',
        # TODO: Replace by assigned hostnames until the DNS aliases are flipped
    }

    monitoring::service { 'labs_ldap_check':
        description   => 'Labs LDAP ',
        check_command => 'check_ldap!dc=wikimedia,dc=org',
        critical      => true,
    }
}
