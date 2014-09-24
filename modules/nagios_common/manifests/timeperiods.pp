# = Class: nagios_common::timeperiods
# Collection of custom nagios check plugins we use
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
#   Defaults to 'root'
#
# [*group*]
#   The group which should own the check config files.
#   Defaults to 'root'
#
class nagios_common::timeperiods(
    $ensure = present,
    $config_dir = '/etc/icinga',
    $owner = 'root',
    $group = 'root',
) {
    file { "$config_dir/timeperiods":
        ensure => $ensure,
        source => 'puppet:///modules/nagios_common/timeperiods.cfg',
        owner  => $owner,
        group  => $group,
    }
}
