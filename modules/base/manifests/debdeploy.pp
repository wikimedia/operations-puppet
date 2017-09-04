# == Class: base::debdeploy
#
# debdeploy, used to rollout software updates. Updates are initiated via
# the debdeploy tool on the Salt master (configured via role::debdeploymaster)
#
class base::debdeploy
{
    package { 'debdeploy-minion':
        ensure => present,
    }

    $grains = hiera_hash('debdeploy::grains', {})

    if $grains != {} {
        create_resources(salt::grain, $grains)
    }

    file { '/usr/local/bin/apt-upgrade-activity':
        ensure => present,
        source => 'puppet:///modules/base/apt-upgrade-activity.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    require_package('debdeploy-client')
}
