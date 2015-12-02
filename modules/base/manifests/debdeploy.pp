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

    $dc_grain = hiera_hash('debdeploy::dc_grain', {})

    if $dc_grain != {} {
        create_resources(salt::grain, $dc_grain)
    }

}
