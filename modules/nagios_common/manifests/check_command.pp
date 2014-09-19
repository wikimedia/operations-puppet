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
# [*plugin_content*]
#   String to use as source for the executable plugin file.
#   Defaults to undef, is derived from $plugin_source if not set.
# [*plugin_source*]
#   Path to source for the executable plugin file.
#   Defaults to puppet:///modules/nagios_common/check_commands/$title
#
# [*config_content*]
#   String to use as source for the plugin configuration.
#   Defaults to undef, is derived from $config_source if not set.
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
    $plugin_content = undef,
    $plugin_source = undef,
    $config_content = undef,
    $config_source = undef,
    $owner = 'root',
    $group = 'root',
) {
    # The puppet path of the check command
    if $plugin_content == undef {
        if $plugin_source == undef {
            $plugin_source = "puppet:///modules/nagios_common/check_commands/$title"
        }
        $plugin_content = file($plugin_source)
    }

    if $config_content == undef {
        if $config_source == undef {
            $config_source = "puppet:///modules/nagios_common/check_commands/$title.cfg"
        }
        $config_content = file($config_source)
    }

    file { "/usr/lib/nagios/plugins/$title":
        ensure  => $ensure,
        content => $plugin_content,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
    }

    file { "$conf_dir/commands/$title.cfg":
        ensure  => $ensure,
        content => $config_content,
        owner   => $owner,
        group   => $group,
    }
}
