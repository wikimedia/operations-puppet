class shinken {
    package { [
        'shinken-common',
        'shinken-mod-pickle-retention-file-generic',
        ]:
        ensure => present,
    }

    $managed_dirs = [
        '/etc/shinken',
        '/etc/shinken/arbiters',
        '/etc/shinken/brokers',
        '/etc/shinken/daemons',
        '/etc/shinken/hosts',
        '/etc/shinken/pollers',
        '/etc/shinken/reactionners',
        '/etc/shinken/realms',
        '/etc/shinken/receivers',
        '/etc/shinken/schedulers',
    ]

    # Purge and clean all non puppet shipped configuration
    file { $managed_dirs:
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        recurse => true,
        purge   => true,
        force   => true,
    }
    # But leave modules/packs directories alone
    $unmanaged_dirs = [
        '/etc/shinken/modules',
        '/etc/shinken/packs',
    ]
    file { $unmanaged_dirs:
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        recurse => false,
        purge   => false,
        force   => false,
    }
}
