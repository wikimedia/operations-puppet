# SPDX-License-Identifier: Apache-2.0
# == Class: profile::kerberos::kdc
#
# This class sets up a kdc/kadmind environment preseeding
# Debian package questions to automate as much as possible
# the first deployment. The only thing that it is not automated
# is the first run of the krb5_newrealm command, that is needed
# after installing the krb5-kadmin-server package (dependency of
# krb5-kdc). The user must execute the command upon first run of
# puppet on the host.
#
# == Parameters
#
# [*krb_realm_name*]
#   Kerberos realm name to set.
#
# [*krb_kdc_servers*]
#   List of fully qualified hostnames of the KDC servers.
#
# [*monitoring_enabled*]
#   If monitoring needs to be enabled.
#   Default: false
#
# [*kdc_workers*]
#   The number of workers to be spawned by the KDC
#   Default: 1
#
class profile::kerberos::kdc (
    Stdlib::Fqdn $krb_realm_name          = lookup('kerberos_realm_name'),
    Array[Stdlib::Fqdn] $krb_kdc_servers  = lookup('kerberos_kdc_servers'),
    Optional[Boolean] $monitoring_enabled = lookup('profile::kerberos::kdc::monitoring_enabled', { 'default_value' => false }),
    Integer $kdc_workers                  = lookup('profile::kerberos::kdc::workers', { 'default_value' => 1 }),
) {

    # Debconf preseed values to automate the deployment of the
    # krb5-kdc package without user inputs when the package
    # is installed.
    debconf::set { 'krb5-kdc/purge_data_too':
        type   => 'boolean',
        value  => false,
        before => Package['krb5-kdc'],
    }

    # Instruct debconf to not create the kdc.conf file
    # since we want to use Puppet instead.
    debconf::set { 'krb5-kdc/debconf':
        type   => 'boolean',
        value  => false,
        before => Package['krb5-kdc'],
    }

    # Debconf preseed values to automate the deployment of the
    # krb5-config (dep of krb5-kdc) package without user inputs
    # when the package is installed.
    debconf::set { 'krb5-config/default_realm':
        value  => $krb_realm_name,
        before => Package['krb5-kdc'],
    }

    debconf::set { 'krb5-config/kerberos_servers':
        value  => inline_template('<%= @krb_kdc_servers.join(" ") %>'),
        before => Package['krb5-kdc'],
    }

    debconf::set { 'krb5-config/add_servers':
        type   => 'boolean',
        value  => true,
        before => Package['krb5-kdc'],
    }

    debconf::set { 'krb5-config/add_servers_realm':
        value  => $krb_realm_name,
        before => Package['krb5-kdc'],
    }

    debconf::set { 'krb5-config/read_conf':
        type   => 'boolean',
        value  => true,
        before => Package['krb5-kdc'],
    }

    debconf::set { 'krb5-config/admin_server':
        value  => '',
        before => Package['krb5-kdc'],
    }

    package { 'krb5-kdc':
        ensure => present,
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

    file { '/etc/default/krb5-kdc':
        content => template('profile/kerberos/kdc-default.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        before  => Package['krb5-kdc'],
        notify  => Service['krb5-kdc'],
    }

    # Starting with bullseye the KDC systemd unit restricts write paths, but for
    # some reason /var/log/kerberos/krb5kdc.log isn't in there
    if debian::codename::ge('bullseye') {
        systemd::override { 'kdc-allow-logfile-directory':
            unit    => 'krb5-kdc',
            content => "[Service]\nReadWritePaths=/var/log/kerberos/\n",
        }
    }

    service { 'krb5-kdc':
        ensure  => running,
        require => Package['krb5-kdc'],
    }

    profile::auto_restarts::service { 'krb5-kdc': }

    firewall::service { 'kerberos_kdc_tcp':
        proto    => 'tcp',
        port     => 88,
        src_sets => ['DOMAIN_NETWORKS'],
    }

    firewall::service { 'kerberos_kdc_udp':
        proto    => 'udp',
        port     => 88,
        src_sets => ['DOMAIN_NETWORKS'],
    }

    file { '/srv/backup':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0750',
    }

    file { '/usr/local/sbin/dump_kdc_database':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
        source => 'puppet:///modules/profile/kerberos/kdc/dump_kdc_database',
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

    include ::profile::backup::host
    backup::set { 'krb-srv-backup': }

    # Needed to cope with bursty requests T329525
    sysctl::parameters {'kdc-sysctl':
        priority => 90,
        values   => {
            'net.core.somaxconn' => 16384,
        },
    }

    logrotate::conf { 'kdc':
        ensure => present,
        source => 'puppet:///modules/kerberos/kdc-logrotate.conf',
    }

    systemd::timer::job { 'delete-old-backups-kdc-database':
        description     => 'Daily clean up of old backups of the KDC database',
        command         => '/usr/bin/find /srv/backup -name "kdc_database_.*" -mtime +30 -delete',
        interval        => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* 01:00:00'
        },
        user            => 'root',
        logging_enabled => false,
        require         => [
            File['/srv/backup'],
        ],
    }
}
