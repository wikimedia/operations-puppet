# == Class role::syslog::centralserver
#
# Setup rsyslog as a receiver of cluster wide syslog messages.
#
class role::syslog::centralserver {

    include base::firewall

    system::role { 'role::syslog::centralserver':
        description => 'Central syslog server'
    }

    ferm::service { 'rsyslog-receiver':
        proto   => 'udp',
        port    => 514,
        notrack => true,
    }

    class { 'rsyslog::receiver': }
}
