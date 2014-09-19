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
    $owner = 'root',
    $group = 'root',
    $config_content = undef,
    $config_source = undef,
) {
    # The puppet path of the check command
    $command_puppet_path = "puppet:///modules/nagios_common/check_commands/$title"

    if $content == undef {
        if $source == undef {
            $source = "puppet:///modules/nagios_common/check_commands/$title.cfg"
        }
        $content = file($source)
    }

    file { "/usr/lib/nagios/plugins/$title":
        ensure  => $ensure,
        content => $command_puppet_path,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
    }

    file { "$conf_dir/commands/$title.cfg":
        ensure  => $ensure,
        content => $content,
        owner   => $owner,
        group   => $group,
    }
}
