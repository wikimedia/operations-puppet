# == Define: apache::mod_conf
#
# Custom resource for managing the configuration of Apache modules.
#
# apache::mod and apache::mpm expose a higher-level interface for
# configuring Apache. You probably want to use one of those instead
# of this defined type, which is used internally by other members
# of the Apache module.
#
# === Parameters
#
# [*mod*]
#   Module name. Defaults to the resource title.
#
# [*loadfile*]
#   The .load config file that Puppet should manage.
#   Defaults to the resource title plus a '.load' suffix.
#
# [*conffile*]
#   The .conf config file that Puppet should manage.
#   Defaults to the resource title plus a '.conf' suffix.
#

define apache::mod_conf(
    $ensure   = present,
    $mod      = $title,
    $loadfile = "${title}.load",
    $conffile = "${title}.conf",
    ) {
    include ::apache

    $loadfile_path = "/etc/apache2/mods-available/${loadfile}"
    $conffile_path = "/etc/apache2/mods-available/${conffile}"

    $loadfile_target = "/etc/apache2/mods-enabled/${loadfile}"
    $conffile_path = "/etc/apache2/mods-enabled/${conffile}"

    # Make sure all resources are in place
    File<| path == $loadfile_path or path == $conffile_path |>

    # Edge case: we're adding a .conf file to a resource that's already
    # been enabled. So given a2enmod is a very simple, idempotent
    # shell script we can safely exec it at every puppet run.
    # a2enmod will then do the right thing(TM).
    # OTOH, when we run a2dismod it's enough to be sure we removed the
    # loadfile as it will effectively remove the module from the
    # apache configuration.
    if $ensure == present {
        exec { "ensure_${ensure}_mod_${mod}":
            command => "/usr/sbin/a2enmod ${mod}",
            require => Package['apache2'],
            notify  => Service['apache2'],
        }
    } elsif $ensure == absent {
        exec { "ensure_${ensure}_mod_${mod}":
            command => "/usr/sbin/a2dismod ${mod}",
            onlyif  => "/usr/bin/test -L /etc/apache2/mods-enabled/${loadfile}",
            require => Package['apache2'],
            notify  => Service['apache2'],
        }
    } else {
        fail("'${ensure}' is not a valid value for ensure.")
    }
}
