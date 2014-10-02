# = Class: nagios_common::contacts
#
# Sets up appropriate contacts for notifications
#
# [*ensure*]
#   present or absent, to make the definition
#   present or absent. Defaults to present
#
# [*config_dir*]
#   The base directory to put configuration directory in.
#   Defaults to '/etc/icinga/'
#
# [*template*]
#   puppet URL specifying the template of the contacts.cfg file
#   Defaults to 'nagios_common/contacts.cfg.erb'
#
# [*owner*]
#   The user which should own the check config files.
#   Defaults to 'root'
#
# [*group*]
#   The group which should own the check config files.
#   Defaults to 'root'
#
# [*contacts*]
#   The list of contacts to include in the configuration.
#
class nagios_common::contacts(
    $ensure = present,
    $config_dir = '/etc/icinga',
    $template = 'nagios_common/contacts.cfg.erb',
    $owner = 'root',
    $group = 'root',
    $contacts = [],
) {
    file { "$config_dir/contacts.cfg":
        ensure => $ensure,
        content => template($template),
        owner  => $owner,
        group  => $group,
    }
}
