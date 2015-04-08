# == Class: role::statsdlb
#
# Provisions a statsdlb instance that listens for StatsD metrics on
# on UDP port 8125 and forwards to backends on UDP ports 8126-8133,
# as well as the set of txstatsd backends that listen on these ports.
#
class role::statsdlb {

    # statsdlb

    class { '::statsdlb':
        server_port   => 8125,
        backend_ports => range(8126, 8139),
    }

    nrpe::monitor_service { 'statsdlb':
        description  => 'statsdlb process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1: -C statsdlb',
    }


    # txstatsd back-ends

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

    file { '/usr/local/sbin/txstatsdctl':
        source => 'puppet:///files/txstatsd/txstatsdctl',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        before => Service['txstatsd'],
    }

    service { 'txstatsd':
        ensure   => 'running',
        provider => 'base',
        restart  => '/usr/local/sbin/txstatsdctl restart',
        start    => '/usr/local/sbin/txstatsdctl start',
        status   => '/usr/local/sbin/txstatsdctl status',
        stop     => '/usr/local/sbin/txstatsdctl stop',
    }

    nrpe::monitor_service { 'txstatsd_backends':
        description  => 'txstatsd backend instances',
        nrpe_command => '/usr/local/sbin/txstatsdctl check',
        require      => Service['txstatsd'],
    }

    diamond::collector { 'UDPCollector': }
}
