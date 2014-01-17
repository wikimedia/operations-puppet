# == Class: txstatsd::decommission
#
# Decommission txStatsD by stopping the daemon and removing its
# configuration files.
#
class txstatsd::decommission {
    service { 'txstatsd':
        ensure   => stopped,
        provider => upstart,
    }

    file { '/etc/init/txstatsd.conf':
        ensure  => absent,
        require => Service['txstatsd'],
    }

    file { '/etc/txstatsd':
        ensure  => absent,
        purge   => true,
        force   => true,
        recurse => true,
    }

    group { 'txstatsd':
        ensure  => absent,
        require => User['txstatsd'],
    }

    user { 'txstatsd':
        ensure  => absent,
        require => Service['txstatsd'],
    }

    package { 'python-txstatsd':
        ensure  => absent,
        require => Service['txstatsd'],
    }
}
