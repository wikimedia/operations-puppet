# NSCA - daemon config
class icinga::monitor::nsca::daemon {

    system::role { 'icinga::nsca::daemon': description => 'Nagios Service Checks Acceptor Daemon' }

    require icinga::nsca

    file { '/etc/nsca.cfg':
        source => 'puppet:///private/icinga/nsca.cfg',
        owner  => 'root',
        mode   => '0400',
    }

    service { 'nsca':
        ensure => running,
    }
}

