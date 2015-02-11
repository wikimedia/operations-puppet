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
#   Optional - allows to input a prewritten file as a source.
# [*template*]
#   puppet URL specifying the template of the contacts.cfg file
#   Defaults to 'nagios_common/contacts.cfg.erb'
#
# [*owner*]
#   The user which should own the check config files.
#   Defaults to 'icinga'
#
# [*group*]
#   The group which should own the check config files.
#   Defaults to 'icinga'
#
# [*contacts*]
#   The list of contacts to include in the configuration.
#
class nagios_common::contacts(
    $ensure = present,
    $config_dir = '/etc/icinga',
    $source = undef,
    $template = 'nagios_common/contacts.cfg.erb',
    $owner = 'icinga',
    $group = 'icinga',
    $contacts = [],
    ) {
    if ($source != undef) {
        file { "${config_dir}/contacts.cfg":
            ensure => $ensure,
            source => $source,
            owner  => $owner,
            group  => $group,
            mode   => '0600', # Only $owner:$group can read/write
        }
    } else {
        file { "${config_dir}/contacts.cfg":
            ensure  => $ensure,
            content => template($template),
            owner   => $owner,
            group   => $group,
            mode    => '0600', # Only $owner:$group can read/write
        }
    }
}
