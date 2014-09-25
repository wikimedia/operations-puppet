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
# [*source*]
#   puppet URL specifying the source of the contacts.cfg
#   Defaults to 'puppet:///modules/nagios_common/contacts.cfg'
#
# [*owner*]
#   The user which should own the check config files.
#   Defaults to 'root'
#
# [*group*]
#   The group which should own the check config files.
#   Defaults to 'root'
#
class nagios_common::contacts(
    $ensure = present,
    $config_dir = '/etc/icinga',
    $source = 'puppet:///modules/nagios_common/contacts.cfg',
    $owner = 'root',
    $group = 'root',
) {
    file { "$config_dir/contacts.cfg":
        ensure => $ensure,
        source => $source,
        owner  => $owner,
        group  => $group,
    }
}
