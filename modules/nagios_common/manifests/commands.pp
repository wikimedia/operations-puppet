# = Class: nagios_common::commands::custom
# Collection of custom nagios check plugins we use
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
class nagios_common::commands::custom(
    $config_dir = '/etc/icinga',
    $owner = 'root',
    $group = 'root',
) {
    
    file { "$config_dir/commands":
        ensure => directory,
        owner  => $owner,
        group  => $group,
        mode   => '0755',
    }

    nagios_common::check_command { 'check_graphite': 
        require    => File["$config_dir/commands"],
        config_dir => $config_dir,
        owner      => $owner,
        group      => $group,
    }
}
