# A class to setup the corp OIT LDAP mirror. This is used for cheap recipient
# verification during email accept
# vim: set ts=4 et sw=4:
class role::openldap::corp {
    include ::standard
    include passwords::openldap::corp
    include ::profile::backup::host
    include ::profile::base::firewall

    system::role { 'openldap::corp':
        description => 'Corp OIT openldap Mirror server'
    }

    $master = 'ldap1.corp.wikimedia.org'
    $sync_pass = $passwords::openldap::corp::sync_pass

    # Certificate needs to be readable by slapd
    sslcert::certificate { "ldap-corp.${::site}.wikimedia.org":
        group => 'openldap',
    }

    class { '::openldap':
        server_id     => 3, # 1 and 2 used in OIT
        suffix        => 'dc=corp,dc=wikimedia,dc=org',
        datadir       => '/var/lib/ldap/corp',
        master        => $master,
        sync_pass     => $sync_pass,
        ca            => '/etc/ssl/certs/ca-certificates.crt',
        certificate   => "/etc/ssl/localcerts/ldap-corp.${::site}.wikimedia.org.crt",
        key           => "/etc/ssl/private/ldap-corp.${::site}.wikimedia.org.key",
        extra_acls    => 'openldap/corp-acls.erb',
        extra_schemas => ['wmf-user.schema'],
    }

    ferm::service { 'corp_ldap':
        proto  => 'tcp',
        port   => '389', # Yes, explicitly not supporting LDAPS (port 636)
        srange => '@resolve((dubnium.wikimedia.org pollux.wikimedia.org mx1001.wikimedia.org mx2001.wikimedia.org))',
    }

    monitoring::service { 'corp_ldap_mirror':
        description   => 'Corp OIT LDAP Mirror ',
        check_command => 'check_ldap!dc=corp,dc=wikimedia,dc=org',
        critical      => true,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/LDAP#Troubleshooting',
    }

    backup::openldapset {'openldap_oit':}
    # NOTE: username is in double quotes cause otherwise it get's auto split
    # into array hence the nested quoting
}
