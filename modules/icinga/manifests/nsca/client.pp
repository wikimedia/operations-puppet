# = Class: icinga::nsca::client
#
# Sets up an NSCA client to send passive check results
# to icinga
class icinga::nsca::client {
    package { 'nsca-client':
        ensure => 'installed',
    }

    include ::passwords::icinga
    $nsca_decrypt_password = $::passwords::icinga::nsca_decrypt_password

    file { '/etc/send_nsca.cfg':
        content => template('icinga/send_nsca.cfg.erb'),
        owner   => 'root',
        mode    => '0400',
        require => Package['nsca-client'],
    }
}
