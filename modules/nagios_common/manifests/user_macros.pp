# = Class: nagios_common::user_macros
# Defines $USERn$ macros for nagios compatible implementations
# === Parameters
# [*ensure*]
#   present or absent, to make the definition
#   present or absent
# 
# [*config_dir*]
#   The base directory to put configuration in
#   Eg: /etc/shinken or /etc/icinga
# 
class nagios_common::user_macros(
    $ensure,
    $config_dir,
){
    file { "$config_dir/resource.cfg":
        ensure => $ensure,
        source => 'puppet:///modules/nagios_common/resource.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
}
