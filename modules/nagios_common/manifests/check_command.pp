# = Define: nagios_common::check_command
# Defines a custom check command and configuration for that
# command

# [*ensure*]
#   present or absent, to make the definition
#   present or absent. Defaults to present
#
# [*config_dir*]
#   The base directory to put configuration in.
#   Defaults to '/etc/icinga/'
#
# [*plugin_source*]
#   Path to source for the executable plugin file.
#   Defaults to puppet:///modules/nagios_common/check_commands/$title
#
# [*plugin_source*]
#   Path to source for the plugin configuration.
#   Defaults to puppet:///modules/nagios_common/check_commands/$title.cfg
#
# [*owner*]
#   The user which should own the config file.
#   Defaults to 'root'
#
# [*group*]
#   The group which should own the config file.
#   Defaults to 'root'
#
define nagios_common::check_command(
    $ensure = present,
    $config_dir = '/etc/icinga',
    $plugin_source = "puppet:///modules/nagios_common/check_commands/$title",
    $config_source = "puppet:///modules/nagios_common/check_commands/$title.cfg",
    $owner = 'root',
    $group = 'root',
) {

    file { "/usr/lib/nagios/plugins/$title":
        ensure => $ensure,
        source => $plugin_source,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { "$conf_dir/commands/$title.cfg":
        ensure => $ensure,
        source => $config_source,
        owner  => $owner,
        group  => $group,
    }
}
