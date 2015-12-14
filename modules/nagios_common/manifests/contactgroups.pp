# = Class: nagios_common::contactgroups
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
# [*source*]
#   Allows to input a prewritten file as a source.  Overrides "content" if
#   defined, but "content" is used if this is undefined.
# [*content*]
#   Allows to input the data as a content string.  The default is
#   template('nagios_common/contacts.cfg.erb')
#
class nagios_common::contactgroups(
    $ensure = present,
    $source,
    $config_dir = '/etc/icinga',
    $owner = 'icinga',
    $group = 'icinga',
) {
    file { "${config_dir}/contactgroups.cfg":
        source  => $source,
        owner   => 'shinken',
        group   => 'shinken',
        mode    => '0644',
    }
}
