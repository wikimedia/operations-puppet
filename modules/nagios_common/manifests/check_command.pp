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
# [*config_source*]
#   Path to source for the plugin configuration.
#   Defaults to puppet:///modules/nagios_common/check_commands/$title.cfg
#
# [*config_content*]
#   String content for the plugin configuration.
#   Should not be specified if config_source is specified
#
# [*owner*]
#   The user which should own the config file.
#   Defaults to 'icinga'
#
# [*group*]
#   The group which should own the config file.
#   Defaults to 'icinga'
#
define nagios_common::check_command(
    $ensure = present,
    $config_dir = '/etc/icinga',
    $plugin_source = "puppet:///modules/nagios_common/check_commands/${title}",
    $config_source = undef,
    $config_content = undef,
    $owner = 'icinga',
    $group = 'icinga',
) {


    file { "/usr/lib/nagios/plugins/${title}":
        ensure => $ensure,
        source => $plugin_source,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    if ($config_source == undef) and ($config_content == undef) {
        $real_config_source =  "puppet:///modules/nagios_common/check_commands/${title}.cfg"
    } else {
        $real_config_source = $config_source
    }

    nagios_common::check_command::config { $title:
        ensure     => $ensure,
        source     => $real_config_source,
        content    => $config_content,
        config_dir => $config_dir,
        owner      => $owner,
        group      => $group
    }
}

