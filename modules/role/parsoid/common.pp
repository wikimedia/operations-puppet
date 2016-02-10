# vim: set ts=4 et sw=4:
class role::parsoid::common {
    package { [
        'nodejs',
        'npm',
        'build-essential',
        ]: ensure => present,
    }

    file { '/var/lib/parsoid':
        ensure => directory,
        owner  => parsoid,
        group  => wikidev,
        mode   => '2775',
    }

    file { '/usr/bin/parsoid':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => '0555',
        source => 'puppet:///modules/parsoid/parsoid',
    }

    ferm::service { 'parsoid':
        proto => 'tcp',
        port  => '8000',
    }
}

