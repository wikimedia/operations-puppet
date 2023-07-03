# @summary uninstalls remains of the Diamond service
class diamond() {
    package { [ 'python-statsd', 'diamond' ]:
        ensure => purged,
    }

    systemd::unit { 'diamond':
        ensure   => absent,
        override => true,
        content  => '',
    }

    file { '/etc/diamond':
        ensure  => absent,
        recurse => true,
        force   => true,
        purge   => true,
    }
}
