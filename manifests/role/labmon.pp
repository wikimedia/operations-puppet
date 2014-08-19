# = Class: labmon
# Role for misc. setup of labs monitoring

class role::labmon {

    class { 'role::graphite::labmon': }

    file { '/var/lib/carbon':
        ensure => link,
        target => '/srv/carbon',
        owner => '_graphite',
        group => '_graphite',
        require => Class['role::graphite::labmon']
    }

    include role::txstatsd
}
