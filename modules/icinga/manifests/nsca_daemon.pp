# NSCA - Nagios Service Check Acceptor
# package contains daemon and client script
class icinga::nsca_daemon {

    system::role { 'icinga::nsca_daemon': description => 'Nagios Service Checks Acceptor Daemon' }

    package { 'nsca':
        ensure => latest,
    }

    file { '/etc/nsca.cfg':
        source => 'puppet:///private/icinga/nsca.cfg',
        owner  => 'root',
        mode   => '0400',
        require => Package['nsca'],
    }

    service { 'nsca':
        ensure => running,
        require => File['/etc/nsca.cfg'],
    }

}


