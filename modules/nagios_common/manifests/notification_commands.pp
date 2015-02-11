# = Class: nagios_common::notificationcommands
# Notification commands, to notify people by email/sms
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
# [*lover_name*]
#   Name of thing that gives the recipient love when notifying
#   them via email of bad things that have happened
#
# [*irc_dir_path*]
#   Directory containing files that are used by ircecho to
#   echo notifications to IRC
#
class nagios_common::notification_commands(
    $ensure = present,
    $config_dir = '/etc/icinga',
    $owner = 'icinga',
    $group = 'icinga',
    $lover_name = 'Icinga',
    $irc_dir_path = '/var/log/icinga',
) {
    file { "${config_dir}/notification_commands.cfg":
        ensure  => $ensure,
        content => template('nagios_common/notification_commands.cfg.erb'),
        owner   => $owner,
        group   => $group,
    }
}
