# == Class role::syslog::centralserver
#
# Setup rsyslog as a receiver of cluster wide syslog messages.
#
class role::syslog::centralserver {

    system::role { 'role::syslog::centralserver':
        description => 'Central syslog server'
    }

    ferm::service { 'rsyslog-receiver':
        proto => 'udp',
        port  => 514,
    }

    class { 'rsyslog::receiver': }

    # syslog-ng cleanup
    service { 'syslog-ng':
        ensure => stopped,
    }

    package { ['syslog-ng', 'syslog-ng-core']:
        ensure => absent,
    }

    file { '/etc/logrotate.d/remote-logs':
        ensure => absent,
    }
    file { '/etc/syslog-ng/syslog-ng.conf':
        ensure => absent,
    }
}
