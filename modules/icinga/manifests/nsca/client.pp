# = Class: icinga::nsca::client
#
# Sets up an NSCA client to send passive check results
# to icinga
class icinga::nsca::client {
    package { 'nsca-client':
        ensure => 'installed',
    }

    file { '/etc/send_nsca.cfg':
        # lint:ignore:puppet_url_without_modules
        source  => 'puppet:///private/icinga/send_nsca.cfg',
        # lint:endignore
        owner   => 'root',
        mode    => '0400',
        require => Package['nsca-client'],
    }
}
