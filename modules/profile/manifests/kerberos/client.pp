class profile::kerberos::client (
    $krb_realm_name = hiera('kerberos_realm_name'),
    $krb_kdc_servers = hiera('kerberos_kdc_servers'),
    $krb_kadmin_primary = hiera('kerberos_kadmin_server_primary'),
    $krb_kadmin_fallback = hiera('kerberos_kadmin_server_fallback'),
) {

    file { '/etc/krb5.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/kerberos/krb.conf.erb')
    }

    file { '/usr/local/bin/kerberos-puppet-wrapper':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/kerberos/kerberos-puppet-wrapper.py',
    }

    file { '/var/log/kerberos':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0750',
    }

    file { '/etc/security/keytabs':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    require_package ('krb5-user')
}
