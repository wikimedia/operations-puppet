class profile::kerberos::kdc (
    Stdlib::Fqdn $krb_realm_name = lookup('kerberos_realm_name'),
    Stdlib::Fqdn $krb_kdc_servers = lookup('kerberos_kdc_servers'),
) {
    package { 'krb5-kdc':
        ensure => present,
    }

    service { 'krb5-kdc':
        ensure    => running,
    }
}
