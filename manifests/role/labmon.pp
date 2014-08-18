# = Class: labmon
# Role for misc. setup of labs monitoring

class role::labmon {

    file { '/srv/carbon':
        ensure => directory,
        owner => '_graphite',
        group => '_graphite',
    }

    file { '/var/lib/carbon':
        ensure => link,
        target => '/srv/carbon',
        owner => '_graphite',
        group => '_graphite',
        require => File['/srv/carbon']
    }

    class { 'role::graphite':
        require => File['/var/lib/carbon']
    }
    include role::txtstsd
}
