# LDAP servers for labs (based on OpenLDAP)

class role::openldap::labs {
    include ::standard
    include passwords::openldap::labs
    include ::profile::base::firewall
    include ::profile::backup::host
    include ::profile::prometheus::openldap_exporter

    $ldapconfig = hiera_hash('labsldapconfig', {})
    $ldap_labs_hostname = $ldapconfig['hostname']

    system::role { 'openldap::labs':
        description => 'LDAP servers for labs (based on OpenLDAP)'
    }

    # Certificate needs to be readable by slapd
    sslcert::certificate { $ldap_labs_hostname:
        group => 'openldap',
    }

    $sync_pass = $passwords::openldap::labs::sync_pass
    class { '::openldap':
        sync_pass     => $sync_pass,
        mirrormode    => true,
        suffix        => 'dc=wikimedia,dc=org',
        datadir       => '/var/lib/ldap/labs',
        ca            => '/etc/ssl/certs/ca-certificates.crt',
        certificate   => "/etc/ssl/localcerts/${ldap_labs_hostname}.crt",
        key           => "/etc/ssl/private/${ldap_labs_hostname}.key",
        extra_schemas => ['dnsdomain2.schema', 'nova_sun.schema', 'openssh-ldap.schema',
                          'puppet.schema', 'sudo.schema'],
        extra_indices => 'openldap/labs-indices.erb',
        extra_acls    => 'openldap/labs-acls.erb',
    }

    # Ldap services are used all over the place, including within
    #  labs and on various prod hosts.
    ferm::service { 'labs_ldap':
        proto  => 'tcp',
        port   => '(389 636)',
        srange => '($PRODUCTION_NETWORKS $LABS_NETWORKS)',
    }

    monitoring::service { 'labs_ldap_check':
        description   => 'Labs LDAP ',
        check_command => 'check_ldap!dc=wikimedia,dc=org',
        critical      => false,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/LDAP#Troubleshooting',
    }

    # restart slapd if it uses more than 50% of memory (T130593)
    cron { 'restart_slapd':
        ensure  => present,
        minute  => fqdn_rand(60, $title),
        command => "/bin/ps -C slapd -o pmem= | awk '{sum+=\$1} END { if (sum <= 50.0) exit 1 }' \
        && /bin/systemctl restart slapd >/dev/null 2>/dev/null",
    }

    backup::openldapset {'openldap_labs':}
}
