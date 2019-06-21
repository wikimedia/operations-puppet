class profile::kerberos::kadminserver (
    Stdlib::Fqdn $krb_realm_name = lookup('kerberos_realm_name'),
    Stdlib::Fqdn $krb_kadmin_primary = lookup('kerberos_kadmin_server_primary'),
    Stdlib::Fqdn $krb_kadmin_keytabs_repo = lookup('kerberos_kadmin_keytabs_repo'),
    Array[String] $rsync_secrets_file_auth_users = lookup('profile::kerberos::kadminserver', { 'default_value' => ['kerb'] }),
) {
    package { 'krb5-admin-server':
        ensure => present,
    }

    if $trusted['certname'] != $krb_kadmin_primary {
        service { 'krb5-admin-server':
            ensure    => stopped,
        }
    }

    ferm::service { 'kerberos_kpasswd_tcp':
        proto  => 'tcp',
        port   => '464',
        srange => '$DOMAIN_NETWORKS',
    }

    ferm::service { 'kerberos_kpasswd_udp':
        proto  => 'udp',
        port   => '464',
        srange => '$DOMAIN_NETWORKS',
    }

    # Util script to help generating keytabs
    file{ '/usr/local/sbin/generate_keytabs.py':
        ensure => file,
        mode   => '0550',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/profile/kerberos/generate_keytabs.py',
    }

    # Keytabs will be generated manually, via a script that uses kadmin.local,
    # under /srv/kerberos/keytabs
    file{ '/srv/kerberos':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file{ '/srv/kerberos/keytabs':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0750',
    }

    # Add the rsync server configuration only to the
    # active kerberos host.
    if $trusted['certname'] == $krb_kadmin_primary {
        $ensure_rsync = 'present'
    } else {
        $ensure_rsync = 'absent'
    }

    class { 'rsync::server': }

    $rsync_secrets_file = '/srv/kerberos/rsync_secrets_file'
    file { $rsync_secrets_file:
        ensure    => 'present',
        owner     => 'root',
        group     => 'root',
        mode      => '0400',
        content   => secret('kerberos/rsync_secrets_file'),
        show_diff => false,
        require   => File['/srv/kerberos']
    }

    rsync::server::module { 'srv-keytabs':
        ensure         => $ensure_rsync,
        path           => '/srv/kerberos/keytabs',
        read_only      => 'yes',
        hosts_allow    => [$krb_kadmin_keytabs_repo],
        auto_ferm      => true,
        auto_ferm_ipv6 => true,
        auth_users     => $rsync_secrets_file_auth_users,
        secrets_file   => $rsync_secrets_file,
        require        => File[$rsync_secrets_file],
    }
}
