# == Class role::syslog::centralserver
#
# Setup rsyslog as a receiver of cluster wide syslog messages.
#
class role::syslog::centralserver {

    include ::standard
    include ::base::firewall
    include ::profile::backup::host

    system::role { 'syslog::centralserver':
        description => 'Central syslog server'
    }

    ferm::service { 'rsyslog-receiver_udp':
        proto   => 'udp',
        port    => 514,
        notrack => true,
        srange  => '$PRODUCTION_NETWORKS',
    }

    ferm::service { 'rsyslog-receiver_tcp':
        proto   => 'tcp',
        port    => 6514,
        notrack => true,
        srange  => '$PRODUCTION_NETWORKS',
    }

    class { 'rsyslog::receiver': }

    mtail::program { 'kernel':
        ensure => present,
        source => 'puppet:///modules/mtail/programs/kernel.mtail',
    }
}
