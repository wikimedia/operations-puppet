# == Define: apache::mod_conf
#
# Custom resource for managing the configuration of Apache modules.
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
) {
    include ::apache

    if $ensure == present {
        exec { "ensure_${ensure}_mod_${mod}":
            command => "/usr/sbin/a2enmod ${mod}",
            creates => "/etc/apache2/mods-enabled/${loadfile}",
            require => Package['httpd'],
            notify  => Service['httpd'],
        }
    } elsif $ensure == absent {
        exec { "ensure_${ensure}_mod_${mod}":
            command => "/usr/sbin/a2dismod ${mod}",
            onlyif  => "/usr/bin/test -L /etc/apache2/mods-enabled/${loadfile}",
            require => Package['httpd'],
            notify  => Service['httpd'],
        }
    } else {
        fail("'${ensure}' is not a valid value for ensure.")
    }
}
