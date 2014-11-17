# vim: set ts=4 et sw=4:

@monitoring::group { "openldap_corp_mirror_${::site}": description => 'Corp OIT LDAP Mirror' }

class role::openldap::corp {
    include passwords::openldap::corp

    system::role { 'role::openldap::corp':
        description => 'Corp OIT openldap Mirror server'
    }

    $master = 'ldap1.corp.wikimedia.org'
    $sync_pass = $passwords::openldap::corp::sync_pass

    install_certificate { 'ldap-mirror.wikimedia.org': }

    class { '::openldap':
        server_id   => 3, # 1 and 2 used in OIT
        suffix      => 'dc=corp,dc=wikimedia,dc=org',
        datadir     => '/var/lib/ldap/corp',
        master      => $master,
        sync_pass   => $sync_pass,
        ca          => '/etc/ssl/certs/ca-certificates.crt',
        certificate => "/etc/ssl/certs/ldap-mirror.wikimedia.org.pem",
        key         => "/etc/ssl/private/ldap-mirror.wikimedia.org.key",
    }

    ferm::service { 'corp_ldap':
        proto  => 'tcp',
        port   => '389', # Yes, explicitly not supporting LDAPS (port 636)
        srange => '$ALL_NETWORKS',
    }

    monitoring::service { 'corp_ldap_mirror':
        description   => 'Corp OIT LDAP Mirror ',
        check_command => 'check_ldap!dc=corp,dc=wikimedia,dc=org',
    }
}
