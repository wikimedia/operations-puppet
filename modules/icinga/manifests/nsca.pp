# NSCA - Nagios Service Check Acceptor
# package contains daemon and client script
class icinga::nsca {

    package { 'nsca':
        ensure => latest,
    }

    system::role { 'icinga::nsca_daemon': description => 'Nagios Service Checks Acceptor Daemon' }

    file { '/etc/nsca.cfg':
        source => 'puppet:///private/icinga/nsca.cfg',
        owner  => 'root',
        mode   => '0400',
    }

    service { 'nsca':
        ensure => running,
    }

}


