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

    require_package('debdeploy-client')
}
