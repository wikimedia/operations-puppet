# A class to setup the corp OIT LDAP mirror. This is used for cheap recipient
# verification during email accept
# vim: set ts=4 et sw=4:
class role::openldap::corp {
    include passwords::openldap::corp
    include base::firewall

    system::role { 'role::openldap::corp':
        description => 'Corp OIT openldap Mirror server'
    }

    $master = 'ldap1.corp.wikimedia.org'
    $sync_pass = $passwords::openldap::corp::sync_pass

    sslcert::certificate { 'ldap-mirror.wikimedia.org': }
    # Certificate needs to be readable by slapd
    sslcert::certificate { "ldap-corp.${::site}.wikimedia.org":
        group => 'openldap',
    }

    # NOTE: Temporary while migration to ldap-corp takes place
    $certificate = $::site ? {
        'eqiad' => '/etc/ssl/localcerts/ldap-mirror.wikimedia.org.crt',
        'codfw' => "/etc/ssl/localcerts/ldap-corp.${::site}.wikimedia.org.crt",
    }
    $key = $::site ? {
        'eqiad' => '/etc/ssl/private/ldap-mirror.wikimedia.org.key',
        'codfw' => "/etc/ssl/private/ldap-corp.${::site}.wikimedia.org.key",
    }

    class { '::openldap':
        server_id   => 3, # 1 and 2 used in OIT
        suffix      => 'dc=corp,dc=wikimedia,dc=org',
        datadir     => '/var/lib/ldap/corp',
        master      => $master,
        sync_pass   => $sync_pass,
        ca          => '/etc/ssl/certs/ca-certificates.crt',
        certificate => $certificate,
        key         => $key,
    }

    ferm::service { 'corp_ldap':
        proto  => 'tcp',
        port   => '389', # Yes, explicitly not supporting LDAPS (port 636)
        srange => '$ALL_NETWORKS',
    }

    monitoring::service { 'corp_ldap_mirror':
        description   => 'Corp OIT LDAP Mirror ',
        check_command => 'check_ldap!dc=corp,dc=wikimedia,dc=org',
        critical      => true,
    }
}
