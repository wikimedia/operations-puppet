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
}
