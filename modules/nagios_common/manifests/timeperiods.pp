# = Class: nagios_common::timeperiods
# Custom notification timeperiods, used by notification commands
#
# [*ensure*]
#   present or absent, to make the definition
#   present or absent. Defaults to present
#
# [*config_dir*]
#   The base directory to put configuration directory in.
#   Defaults to '/etc/icinga/'
#
# [*owner*]
#   The user which should own the check config files.
#   Defaults to 'icinga'
#
# [*group*]
#   The group which should own the check config files.
#   Defaults to 'icinga'
#
class nagios_common::timeperiods(
    $ensure = present,
    $config_dir = '/etc/icinga',
    $owner = 'icinga',
    $group = 'icinga',
) {
    file { "${config_dir}/timeperiods.cfg":
        ensure => $ensure,
        source => 'puppet:///modules/nagios_common/timeperiods.cfg',
        owner  => $owner,
        group  => $group,
    }
}
