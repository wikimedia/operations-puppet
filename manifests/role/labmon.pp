# = Class: labmon
# Role for misc. setup of labs monitoring

class role::labmon {

    class { 'role::graphite':
        storage_dir => '/srv/carbon'
    }

    file { '/var/lib/carbon':
        ensure => link,
        target => '/srv/carbon',
        owner => '_graphite',
        group => '_graphite',
        require => Class['role::graphite']
    }

    include role::txtstsd
}
