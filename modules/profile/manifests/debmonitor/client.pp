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
    String $debmonitor_server = hiera('debmonitor'),
) {
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

    # Setup the daily reconciliation cron in case any debmonitor update fails.
    $cron = '/usr/bin/systemd-cat -t "debmonitor-client" /usr/bin/debmonitor-client'

    cron { 'debmonitor-client':
        command => $cron,
        user    => 'debmonitor',
        hour    => fqdn_rand(23, $title),
        minute  => fqdn_rand(59, $title),
    }
}
