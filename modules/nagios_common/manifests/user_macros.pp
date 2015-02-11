# = Class: nagios_common::user_macros
# Defines $USERn$ macros for nagios compatible implementations
# === Parameters
# [*ensure*]
#   present or absent, to make the definition
#   present or absent. Defaults to present
#
# [*config_dir*]
#   The base directory to put configuration in.
#   Defaults to '/etc/icinga/'
#
# [*owner*]
#   The user which should own the config file.
#   Defaults to 'icinga'
#
# [*group*]
#   The group which should own the config file.
#   Defaults to 'icinga'
#
class nagios_common::user_macros(
    $ensure = present,
    $config_dir = '/etc/icinga/',
    $owner = 'icinga',
    $group = 'icinga',
){
    file { "${config_dir}/resource.cfg":
        ensure => $ensure,
        source => 'puppet:///modules/nagios_common/resource.cfg',
        owner  => $owner,
        group  => $group,
        mode   => '0644',
    }
}
