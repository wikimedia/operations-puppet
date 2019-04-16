class profile::kerberos::kadminserver (
    Stdlib::Fqdn $krb_realm_name = lookup('kerberos_realm_name'),
    Stdlib::Fqdn $krb_kadmin_primary = lookup('kerberos_kadmin_server_primary'),
) {
    package { 'krb5-admin-server':
        ensure => present,
    }

    if $trusted['certname'] != $krb_kadmin_primary {
        service { 'krb5-admin-server':
            ensure    => stopped,
        }
    }
}
