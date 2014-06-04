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

    generic::systemuser { 'txstatsd':
        ensure        => absent,
        name          => 'txstatsd',
        require       => Service['txstatsd'],
    }

    package { 'python-txstatsd':
        ensure  => absent,
        require => Service['txstatsd'],
    }
}
