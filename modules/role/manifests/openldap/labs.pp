# LDAP servers for labs (based on OpenLDAP)

class role::openldap::labs {
    include ::standard
    include passwords::openldap::labs
    include ::profile::base::firewall
    include ::profile::backup::host

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
    $monitor_pass = $passwords::openldap::labs::monitor_pass
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
    }

    # restart slapd if it uses more than 50% of memory (T130593)
    cron { 'restart_slapd':
        ensure  => present,
        minute  => fqdn_rand(60, $title),
        command => "/bin/ps -C slapd -o pmem= | awk '{sum+=\$1} END { if (sum <= 50.0) exit 1 }' \
        && /bin/systemctl restart slapd >/dev/null 2>/dev/null",
    }

    require_package('prometheus-openldap-exporter')

    $prometheus_ferm_nodes = join(hiera('prometheus_nodes'), ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    ferm::service { 'prometheus-varnish-exporter':
        proto  => 'tcp',
        port   => '9142',
        srange => $ferm_srange,
    }

    file { '/etc/prometheus/openldap-exporter.yaml':
        ensure  => present,
        mode    => '0440',
        owner   => 'prometheus',
        group   => 'prometheus',
        content => template('openldap/prometheus.conf.erb'),
        notify  => Service['prometheus-openldap-exporter'],
    }

    service { 'prometheus-openldap-exporter':
        ensure  => running,
        require => File['prometheus-openldap-exporter'],
    }

    backup::openldapset {'openldap_labs':}
    diamond::collector { 'OpenLDAP':
        settings => {
            host     => $ldap_labs_hostname,
            username => '"cn=monitor,dc=wikimedia,dc=org"',
            password => $monitor_pass,
        },
    }
}
