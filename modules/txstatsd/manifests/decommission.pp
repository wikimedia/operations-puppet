# == Class: txstatsd::decommission
#
# Decommission txStatsD by stopping the daemon and removing its
# configuration files.
#
class txstatsd::decommission {
    file { '/etc/init/txstatsd.conf':
        ensure  => absent,
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
    }

    package { 'python-txstatsd':
        ensure  => absent,
    }
}
