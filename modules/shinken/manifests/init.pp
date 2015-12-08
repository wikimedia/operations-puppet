# Class: shinken
#
# Install shinken, create configuration directories hierarchy
#
class shinken {

    if ! os_version('debian >= jessie') {
        # Debian Jessie is the first distro to have shinken > 2.0 and it's
        # packaging is backwards incompatible with the previous versions
        fail('This will not work with anything lower than debian jessie')
    }
    package { [
        'shinken-common',
        'shinken-mod-pickle-retention-file-generic',
        ]:
        ensure => present,
    }

    $managed_dirs = [
        '/etc/shinken',
        '/etc/shinken/generated',
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
        mode    => '0555',
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
        mode    => '0555',
        recurse => false,
        purge   => false,
        force   => false,
    }
}
