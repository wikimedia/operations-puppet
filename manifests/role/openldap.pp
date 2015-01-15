# vim: set ts=4 et sw=4:
@monitoring::group { 'openldap_corp_mirror_eqiad':
    description => 'Corp OIT LDAP Mirror'
}
@monitoring::group { 'openldap_corp_mirror_codfw':
    description => 'Corp OIT LDAP Mirror codfw'
}

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
        certificate => "/etc/ssl/localcerts/ldap-mirror.wikimedia.org.crt",
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
        critical      => true,
    }
}
