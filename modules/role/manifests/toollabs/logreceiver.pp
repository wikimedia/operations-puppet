# Recevies logs from rsyslogd via UDP and stores it centrally
class role::toollabs::logreceiver {
    include base::firewall

    system::role { 'role::tools::logreceiver':
        description => 'Central syslog server'
    }

    ferm::service { 'rsyslog-receiver':
        proto   => 'udp',
        port    => 514,
        notrack => true,
    }

    labs_lvm::volume { 'syslog':
        mountat => '/srv',
    }

    class { 'rsyslog::receiver':
        require            => Labs_lvm::Volume['syslog'],
        log_retention_days => 15, #We don't have that much space!
    }
}