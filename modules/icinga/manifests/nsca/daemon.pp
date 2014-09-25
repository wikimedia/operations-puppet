# = Class: icinga::nsca::daemon
#
# Sets up an NSCA daemon for listening to passive check
# results from hosts
class icinga::nsca::daemon {

    system::role { 'icinga::nsca::daemon': description => 'Nagios Service Checks Acceptor Daemon' }

    package { 'nsca':
        ensure => latest,
    }

    file { '/etc/nsca.cfg':
        source  => 'puppet:///private/icinga/nsca.cfg',
        owner   => 'root',
        mode    => '0400',
        require => Package['nsca'],
    }

    service { 'nsca':
        ensure  => running,
        require => File['/etc/nsca.cfg'],
    }
}
