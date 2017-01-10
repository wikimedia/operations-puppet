# = Class: nagios_common::contactgroups
#
# Sets up appropriate contacts for notifications
#
# [*source*]
#   Allows to input a prewritten file as a source.  Overrides "content" if
#   defined, but "content" is used if this is undefined.
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
class nagios_common::contactgroups(
    $source,
    $ensure = present,
    $config_dir = '/etc/icinga',
    $owner = 'icinga',
    $group = 'icinga',
) {
    file { "${config_dir}/contactgroups.cfg":
        source => $source,
        owner  => $owner,
        group  => $group,
        mode   => '0644',
    }
}
