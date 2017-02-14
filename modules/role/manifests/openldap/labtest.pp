# LDAP servers for labs test cluster
#  this is a fork of role::openldap::labs, minus the mirroring and monitoring

class role::openldap::labtest {
    include passwords::openldap::labtest
    include ::base::firewall

    $ldapconfig = hiera_hash('labsldapconfig', {})
    $ldap_labs_hostname = $ldapconfig['hostname']

    system::role { 'role::openldap::labtest':
        description => 'LDAP servers for labs test cluster (based on OpenLDAP)'
    }

    # Certificate needs to be readable by slapd
    sslcert::certificate { $ldap_labs_hostname:
        group => 'openldap',
    }

    class { '::openldap':
        server_id     => 1,
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
}
