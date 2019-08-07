class profile::kerberos::kdc (
    Stdlib::Fqdn $krb_realm_name = lookup('kerberos_realm_name'),
    Array[Stdlib::Fqdn] $krb_kdc_servers = lookup('kerberos_kdc_servers'),
    Optional[Boolean] $monitoring_enabled = lookup('profile::kerberos::kdc::monitoring_enabled', { 'default_value' => false }),
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

    file { '/srv/backup':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0750',
    }

    file { '/usr/local/sbin/dump_kdc_database':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0550',
        content => 'puppet:///modules/profile/kdc/dump_kdc_database',
    }

    systemd::timer::job { 'backup-kdc-database':
        description        => 'Daily dump of the KDC database',
        command            => '/usr/local/sbin/dump_kdc_database',
        interval           => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* 00:00:00'
        },
        user               => 'root',
        monitoring_enabled => $monitoring_enabled,
        logging_enabled    => false,
        require            => [
            File['/usr/local/sbin/dump_kdc_database'],
            File['/srv/backup'],
        ],
    }

    systemd::timer::job { 'delete-old-backups-kdc-database':
        description        => 'Daily clean up of old backups of the KDC database',
        command            => 'find /srv/backup -name "kdc_database_.*" -mtime +30 -delete',
        interval           => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* 01:00:00'
        },
        user               => 'root',
        monitoring_enabled => false,
        logging_enabled    => false,
        require            => [
            File['/srv/backup'],
        ],
    }
}
