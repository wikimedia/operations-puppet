# == Class: role::statsdlb
#
# Provisions a statsdlb instance that listens for StatsD metrics on
# on UDP port 8125 and forwards to backends on UDP ports 8126-8133.
#
class role::statsdlb {
    class { '::statsdlb':
        server_port   => 8125,
        backend_ports => range(8126, 8135),
    }

    package { 'python-txstatsd': }

    file { '/etc/txstatsd':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        recurse => true,
        purge   => true,
        force   => true,
        source  => 'puppet:///files/txstatsd/backends',
    }

    file { '/etc/init/txstatsd':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        recurse => true,
        purge   => true,
        force   => true,
        source  => 'puppet:///files/txstatsd/init',
    }

    group { 'txstatsd':
        ensure => present,
    }

    user { 'txstatsd':
        ensure     => present,
        gid        => 'txstatsd',
        shell      => '/bin/false',
        home       => '/nonexistent',
        system     => true,
        managehome => false,
    }

    diamond::collector { 'UDPCollector': }
}
