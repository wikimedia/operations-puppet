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

    require_package('python3-pypuppetdb')
}
