# == Class: base::debdeploy
#
# debdeploy, used to rollout software updates. Updates are initiated via
# the debdeploy tool on the Cumin master(s)
#
class base::debdeploy
{
    file { '/usr/local/bin/apt-upgrade-activity':
        ensure => present,
        source => 'puppet:///modules/base/apt-upgrade-activity.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/usr/local/sbin/reboot-host':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
        source => 'puppet:///modules/base/reboot-host',
    }

    file {'/etc/debdeploy-client':
      ensure  => directory,
    }

    require_package('debdeploy-client', 'python-dateutil')
}
