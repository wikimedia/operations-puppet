class profile::kerberos::kdc (
    Stdlib::Fqdn $krb_realm_name = lookup('profile::kerberos::realm_name'),
    Stdlib::Fqdn $krb_kdc_servers = lookup('profile::kerberos::kdc_servers'),
) {
    package { 'krb5-kdc':
        ensure => present,
    }

    service { 'krb5-kdc':
        ensure    => running,
    }
}
