# Class: profile::debmonitor::client
#
# This profile installs the Debmonitor client and its configuration.
#
# Actions:
#       Expose Puppet certs for the debmonitor user
#       Install DebMonitor client's configuration
#       Install DebMonitor client
#
# Sample Usage:
#       include ::profile::debmonitor::client
#
class profile::debmonitor::client (
    Stdlib::Host $debmonitor_server = lookup('debmonitor'),
){
    $base_path = '/etc/debmonitor'
    $cert = "${base_path}/ssl/cert.pem"
    $private_key = "${base_path}/ssl/server.key"
    $ca = '/etc/ssl/certs/Puppet_Internal_CA.pem'

    # On Debmonitor server hosts this is already defined by service::uwsgi.
    if !defined(File[$base_path]) {
        # Create directory for the exposed Puppet certs.
        file { $base_path:
            ensure => directory,
            owner  => 'debmonitor',
            group  => 'debmonitor',
            mode   => '0555',
        }
    }

    # Create user and group to which expose the Puppet certs.
    group { 'debmonitor':
        ensure => present,
        system => true,
    }

    user { 'debmonitor':
        ensure     => present,
        gid        => 'debmonitor',
        shell      => '/bin/bash',
        home       => '/nonexistent',
        managehome => false,
        system     => true,
        comment    => 'DebMonitor system user',
    }

    ::base::expose_puppet_certs { $base_path:
        user            => 'debmonitor',
        group           => 'debmonitor',
        provide_private => true,
    }

    # Create the Debmonitor client configuration file.
    file { '/etc/debmonitor.conf':
        ensure  => present,
        owner   => 'debmonitor',
        group   => 'debmonitor',
        mode    => '0440',
        content => template('profile/debmonitor/client/debmonitor.conf.erb'),
    }

    # Install the package after the configuration file and the exposed Puppet certs are in place.
    package { 'debmonitor-client':
        ensure  => installed,
        require => [
            File['/etc/debmonitor.conf'],
            Base::Expose_puppet_certs[$base_path],
        ],
    }

    $debmon_client_job = '/usr/bin/systemd-cat -t "debmonitor-client" /usr/bin/debmonitor-client'
    # Setup the daily reconciliation job in case any debmonitor update fails.
    cron { 'debmonitor-client':
        ensure  => 'absent',
        command => $debmon_client_job,
        user    => 'debmonitor',
        hour    => fqdn_rand(23, $title),
        minute  => fqdn_rand(59, $title),
    }

    $hour = Integer(seeded_rand(24, $::fqdn))
    $minute = Integer(seeded_rand(60, $::fqdn))

    systemd::timer::job { 'debmonitor-client':
        ensure      => 'present',
        user        => 'debmonitor',
        description => 'reconciliation job in case any debmonitor update fails',
        command     => $debmon_client_job,
        interval    => {'start' => 'OnCalendar', 'interval' => "*-*-* ${hour}:${minute}:00"},
    }
}
