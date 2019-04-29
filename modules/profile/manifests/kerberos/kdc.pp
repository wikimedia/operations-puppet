class profile::kerberos::kdc (
    Stdlib::Fqdn $krb_realm_name = lookup('kerberos_realm_name'),
    Array[Stdlib::Fqdn] $krb_kdc_servers = lookup('kerberos_kdc_servers'),
) {
    package { 'krb5-kdc':
        ensure => present,
        before => Service['krb5-kdc'],
    }

    file {'/etc/krb5kdc':
        ensure => directory,
        mode   => '0700',
    }

    file { '/etc/krb5kdc/kdc.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/kerberos/kdc.conf.erb'),
        before  => Package['krb5-kdc'],
    }

    file { '/etc/krb5kdc/kadm5.acl':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/profile/kerberos/kadm5.acl',
        before => Package['krb5-kdc'],
    }

    service { 'krb5-kdc':
        ensure    => running,
    }

    ferm::service { 'kerberos_kdc_tcp':
        proto  => 'tcp',
        port   => '88',
        srange => '$DOMAIN_NETWORKS',
    }

    ferm::service { 'kerberos_kdc_udp':
        proto  => 'udp',
        port   => '88',
        srange => '$DOMAIN_NETWORKS',
    }
}
