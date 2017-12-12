# = Class: icinga::nsca::daemon
#
# Sets up an NSCA daemon for listening to passive check
# results from hosts
class icinga::nsca::daemon {

    package { 'nsca':
        ensure => 'present',
    }

    include ::passwords::icinga
    $nsca_decrypt_password = $::passwords::icinga::nsca_decrypt_password

    file { '/etc/nsca.cfg':
        content => template('icinga/nsca.cfg.erb'),
        owner   => 'root',
        mode    => '0400',
        require => Package['nsca'],
    }

    service { 'nsca':
        ensure  => running,
        require => File['/etc/nsca.cfg'],
    }
}
