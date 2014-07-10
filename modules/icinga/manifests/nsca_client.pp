# NSCA - client config
class icinga::nsca_client {

    package { 'nsca-client':
        ensure => 'installed',
    }

    file { '/etc/send_nsca.cfg':
        source => 'puppet:///private/icinga/send_nsca.cfg',
        owner  => 'root',
        mode   => '0400',
        require => Package['nsca-client'],
    }
}

