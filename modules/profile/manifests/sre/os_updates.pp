# == Class profile::sre::os_updates
#
# Installs a script to track the status of OS upgrades across our fleet
class profile::sre::os_updates {

    file { '/usr/local/bin/os-updates-report':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/sre/os-updates-report.py',
    }

    wmflib::dir::mkdir_p('/etc/wikimedia/os-updates', {
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    })

    file { '/etc/wikimedia/os-updates/os-updates-tracking.cfg':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/profile/sre/os-updates-tracking.cfg',
    }

    file { '/etc/wikimedia/os-updates/owners.yaml':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/profile/sre/owners.yaml',
    }

    file { '/etc/wikimedia/os-updates/stretch.yaml':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/profile/sre/stretch.yaml',
    }

    ensure_packages(['python3-pypuppetdb', 'python3-dominate'])
}
