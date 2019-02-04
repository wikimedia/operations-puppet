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

    # stop the default service and rely on statsite::instance to do the
    # right thing
    exec { 'mask_statsite':
        command => '/bin/systemctl mask statsite.service',
        creates => '/etc/systemd/system/statsite.service',
        before  => Package['statsite'],
    }

    systemd::unit { 'statsite@':
        ensure  => present,
        restart => true,
        content => systemd_template('statsite@')
    }

    systemd::unit { 'statsite-instances':
        ensure  => present,
        restart => true,
        content => systemd_template('statsite-instances')
    }

    rsyslog::conf { 'statsite':
        source   => 'puppet:///modules/statsite/rsyslog.conf',
        priority => 20,
    }
}
