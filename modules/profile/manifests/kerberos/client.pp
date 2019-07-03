class profile::kerberos::client (
    Stdlib::Fqdn $krb_realm_name = lookup('kerberos_realm_name'),
    Array[Stdlib::Fqdn] $krb_kdc_servers = lookup('kerberos_kdc_servers'),
    Stdlib::Fqdn $krb_kadmin_primary = lookup('kerberos_kadmin_server_primary'),
) {

    class { 'kerberos::wrapper': }

    $run_command_script = $::kerberos::wrapper::kerberos_run_command_script

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

    file { '/etc/security/keytabs':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    require_package ('krb5-user')
}
