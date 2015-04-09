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

    file { '/etc/statsite':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    if os_version('ubuntu >= precise') {
        file { '/sbin/statsitectl':
            source => 'puppet:///modules/statsite/statsitectl',
            mode   => '0755',
        }

        file { '/etc/init/statsite':
            source  => 'puppet:///modules/statsite/init',
            recurse => true,
            purge   => true,
            force   => true,
        }

        # prevent the system-wide statsite from starting
        file { '/etc/init/statsite.override':
            content => 'manual',
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

    if os_version('debian >= jessie') {
        service { 'statsite':
            ensure   => 'running',
            require  => Package['statsite'],
        }
    }
}
