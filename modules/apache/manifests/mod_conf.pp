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
define apache::mod_conf(
    $ensure   = present,
    $mod      = $title,
    $loadfile = "${title}.load",
)
{
    validate_ensure($ensure)

    include ::apache

    if $ensure == present {
        exec { "ensure_${ensure}_mod_${mod}":
            command => "/usr/sbin/a2enmod ${mod}",
            creates => "/etc/apache2/mods-enabled/${loadfile}",
            require => Package['apache2'],
            notify  => Service['apache2'],
        }
    } else {
        exec { "ensure_${ensure}_mod_${mod}":
            command => "/usr/sbin/a2dismod -f ${mod}",
            onlyif  => "/usr/bin/test -L /etc/apache2/mods-enabled/${loadfile}",
            require => Package['apache2'],
            notify  => Service['apache2'],
        }
    }
}
