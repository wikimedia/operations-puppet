# == Define: apache::mod_files
#
# Custom resource form managing config files for apache modules.
#
# This define completes the apache::mod_conf define and allows you to
# override the existing, distribution provided config files for your
# modules.
# Note that when not absented, this resource will only define virtual
# file resources that will be realized by the corresponding
# apache::mod_conf or, at higher level, by the corresponding
# apache::mpm or apache::mod::<module> classes.
#
# === Parameters
#
# [*conf_source*]
#   Source file for the .conf module config file
#
# [*load_source*]
#   Same thing for the load file
#
# [*conf_content*]
#   Content for the .conf module config file
#
# [*load_content*]
#   Same thing for the load file
#

define apache::mod_files(
    $ensure       = 'present',
    $conf_source  = undef,
    $conf_content = undef,
    $load_source  = undef,
    $load_content = undef,
){
    $load_file = "/etc/apache2/mods_available/${title}.load"
    $conf_file = "/etc/apache2/mods_available/${title}.conf"
    # Not that ensure == 'absent' is *really* a corner-case as most
    # modules configs are taken care of by the corresponding debian
    # package. There may be cases where we added manually a config and
    # we want to remove it for tidiness.
    #
    if $ensure == 'absent' {
        file { [$conf_file, $load_file]:
            ensure => absent,
        }
    } else {
        # Safeguards
        if $load_source != undef and $load_content != undef  { fail('"source" and "content" are mutually exclusive') }
        if $conf_source != undef and $conf_content != undef  { fail('"source" and "content" are mutually exclusive') }

        # Virtual resource, will be realized when the corresponding
        # mod_conf gets declared.
        if ($load_source != undef or $load_content != undef) {
            @file { $load_file:
                ensure  => present,
                content => $load_content,
                source  => $load_source,
                owner   => 'root',
                group   => 'root',
                mode    => '0444',
            }
        } else {
            # We need this file to be defined anyways, even if empty
            # See mpm_* config on precise
            @file { $load_file:
                ensure => present,
                owner  => 'root',
                group  => 'root',
                mode   => '0444',
            }
        }
        if ($conf_source != undef or $conf_content != undef) {
            @file { $conf_file:
                ensure  => present,
                content => $conf_content,
                source  => $conf_source,
                owner   => 'root',
                group   => 'root',
                mode    => '0444',
            }
        }
    }
}
