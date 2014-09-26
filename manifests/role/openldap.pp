# vim: set ts=4 et sw=4:

@monitor_group { 'openldap_oit_mirror_eqiad': description => 'OIT LDAP Mirror' }
@monitor_group { 'openldap_oit_mirror_codfw': description => 'OIT LDAP Mirror' }

class role::openldap::oit {
    include passwords::openldap::oit

    system::role { 'role::openldap':
        description => 'OIT openldap Mirror server'
    }

    # TODO: Define this
    $master = 'server.corp.wikimedia.org'
    $sync_pass = $passwords::openldap::oit::sync_pass

    # TODO: Clear out what certificate we will use
    install-certificate { 'plutonium.wikimedia.org': }

    class { '::openldap':
        server_id   => 3, # 1 and 2 used in OIT
        suffix      => 'dc=corp,dc=wikimedia,dc=org',
        datadir     => '/var/lib/ldap/corp',
        master      => $master,
        sync_pass   => $sync_pass,
        ca          => '/etc/ssl/certs/ca-certificates.crt',
        certificate => "/etc/ssl/certs/plutonium.wikimedia.org.crt",
        key         => "/etc/ssl/private/plutonium.wikimedia.org.key",
    }

    ferm::service { 'oit_ldap':
      proto => 'tcp',
      port  => '389' # Yes, explicitly not supporting LDAPS (port 636)
    }

    monitor_service { 'oit_ldap_mirror':
      description   => 'OIT LDAP Mirror ',
      check_command => 'check_ldap!dc=corp,dc=wikimedia,dc=org',
    }
}
