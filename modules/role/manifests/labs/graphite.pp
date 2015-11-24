# = Class: role::labs::graphite
# Sets up graphite instance for monitoring labs, running on production hardware.
# Instance is open to all, no password required to see metrics
class role::labs::graphite {

    class { 'role::graphite::base':
        storage_dir => '/srv/carbon',
        auth        => false,
        hostname    => 'graphite.wmflabs.org',
    }

    include graphite::labs::archiver

    file { '/var/lib/carbon':
        ensure  => link,
        target  => '/srv/carbon',
        owner   => '_graphite',
        group   => '_graphite',
        require => Class['role::graphite::base']
    }

    include role::statsite
}
