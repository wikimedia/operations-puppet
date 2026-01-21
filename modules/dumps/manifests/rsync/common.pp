# @summary Manages the rsyncd server installation
# @param user Dumps user
# @param group Dumps group
class dumps::rsync::common(
    String[1] $user,
    String[1] $group,
) {
    ensure_packages('rsync')

    file { '/etc/rsyncd.d':
        ensure  => absent,
        recurse => true,
        force   => true,
        purge   => true,
    }

    concat { '/etc/rsyncd.conf':
        ensure => present,
        notify => Service['rsync'],
    }

    concat::fragment { 'rsyncd-00-globalopts':
        target  => '/etc/rsyncd.conf',
        content => template('dumps/rsync/rsyncd.conf.globalopts.erb'),
        order   => '00-globalopts',
        notify  => Service['rsync'],
    }

    service { 'rsync':
        ensure => running,
        enable => true,
    }

    file { '/etc/default/rsync':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('dumps/rsync/rsync.default.erb'),
    }
}
