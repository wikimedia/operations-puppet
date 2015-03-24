# == Class: statsite
#
# Configure statsite https://github.com/armon/statsite
# To add individual instances, use statsite::instance
#
# === Parameters
#
# [*port*]
#   Port to listen for messages on over UDP.
#
# [*graphite_host*]
#   Send metrics to graphite on this host
#
# [*graphite_port*]
#   Send metrics to graphite on this port
#
# [*input_counter*]
#   Use this metric to report self-statistics
#
# [*extended_counters*]
#   Export additional metrics for counters

class statsite {
    package { 'statsite':
        ensure => present,
    }

    file { '/sbin/statsitectl':
        source => 'puppet:///modules/statsite/statsitectl',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/init/statsite':
        source  => 'puppet:///modules/statsite/init',
        owner   => 'root',
        group   => 'root',
        recurse => true,
        purge   => true,
        force   => true,
    }

    # prevent the system-wide statsite from starting
    file { '/etc/init/statsite.override':
        content => "manual\n",
        owner   => 'root',
        group   => 'root',
        before  => Package['statsite'],
    }

    service { 'statsite':
        ensure   => 'running',
        provider => 'base',
        restart  => '/sbin/statsitectl restart',
        start    => '/sbin/statsitectl start',
        status   => '/sbin/statsitectl status',
        stop     => '/sbin/statsitectl stop',
        require  => Package['statsite'],
    }
}
