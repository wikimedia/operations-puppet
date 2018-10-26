class profile::kerberos::client (
    $krb_realm_name = hiera('kerberos::realm_name'),
    $krb_kdc_servers = hiera('kerberos::kdc_servers'),
    $krb_kadmin_primary = hiera('kerberos::kadmin_server_primary'),
    $krb_kadmin_fallback = hiera('kerberos::kadmin_server_fallback'),
) {

    file { '/etc/krb5.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/kerberos/krb.conf.erb')
    }

    file { '/var/log/kerberos':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0750',
    }

    require_package ('krb5-user')
}
