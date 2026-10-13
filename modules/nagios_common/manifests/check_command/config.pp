# = Define: nagios_common::check_command::config
# Sets up a check_command without an associated custom
# check script. Useful when we want a command that just
# builds on other existing commands
#
# [*ensure*]
#   present or absent, to make the definition
#   present or absent. Defaults to present
#
# [*config_dir*]
#   The base directory to put configuration in.
#   Defaults to '/etc/icinga/'
#
# [*source*]
#   Path to source for the plugin configuration.
#   Defaults to puppet:///modules/nagios_common/check_commands/$title.cfg
#
# [*content*]
#   String content to use for the plugin configuration.
#   Should not be used with the source parameter.
#
# [*owner*]
#   The user which should own the config file.
#   Defaults to 'icinga'
#
# [*group*]
#   The group which should own the config file.
#   Defaults to 'icinga'
#
define nagios_common::check_command::config(
    $ensure = present,
    $config_dir = '/etc/icinga',
    $source = undef,
    $content = undef,
    $owner = 'icinga',
    $group = 'icinga',
) {
    # Don't look up a source or content when removing the file: the default
    # source may no longer exist once the check has been deleted from the repo.
    if $ensure == 'absent' {
        $real_source = undef
        $real_content = undef
    } elsif ($source == undef) and ($content == undef) {
        $real_source = "puppet:///modules/nagios_common/check_commands/${title}.cfg"
        $real_content = undef
    } else {
        $real_source = $source
        $real_content = $content
    }

    file { "${config_dir}/commands/${title}.cfg":
        ensure  => $ensure,
        source  => $real_source,
        content => $real_content,
        owner   => $owner,
        group   => $group,
        notify  => Service['icinga'],
    }
}
