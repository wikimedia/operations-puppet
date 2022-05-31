class profile::openldap_corp (
    String $master             = lookup('profile::openldap_corp::master_server'),
    Integer $server_id         = lookup('profile::openldap_corp::server_id'),
    Array[String] $ldap_access = lookup('profile::openldap_corp::ldap_access'),
){
    include passwords::openldap::corp

    $sync_pass = $passwords::openldap::corp::sync_pass


    $suffix = 'dc=corp,dc=wikimedia,dc=org'
    class { '::openldap':
        server_id     => $server_id,   # 1 and 2 used in OIT
        suffix        => $suffix,
        datadir       => '/var/lib/ldap/corp',
        master        => $master,
        sync_pass     => $sync_pass,
        ca            => '/etc/ssl/certs/ca-certificates.crt',
        certificate   => "/etc/ssl/localcerts/ldap-corp.${::site}.wikimedia.org.crt",
        key           => "/etc/ssl/private/ldap-corp.${::site}.wikimedia.org.key",
        extra_acls    => template('openldap/corp-acls.erb'),
        extra_schemas => ['wmf-user.schema'],
    }

    # Certificate needs to be readable by slapd
    sslcert::certificate { "ldap-corp.${::site}.wikimedia.org":
        group => 'openldap',
    }

    $ldap_corp_ferm = join($ldap_access, ' ')
    ferm::service { 'corp_ldap':
        proto  => 'tcp',
        port   => '389', # Yes, explicitly not supporting LDAPS (port 636)
        srange => "@resolve((${ldap_corp_ferm}))",
    }

    monitoring::service { 'corp_ldap_mirror':
        description   => 'Corp OIT LDAP Mirror ',
        check_command => 'check_ldap!dc=corp,dc=wikimedia,dc=org',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/LDAP#Troubleshooting',
    }

    backup::openldapset { 'openldap' :}
}
