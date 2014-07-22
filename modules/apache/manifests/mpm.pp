# == Define: apache::mpm
#
# This resource configures an Apache Multi-Processing Module (MPM).
#
# === Parameters
#
# [*mpm*]
#   Name of the MPM. Defaults to resource title.
#
define apache::mpm( $mpm = $title ) {
    include ::apache

    if $mpm !~ /^(prefork|worker|event)$/ {
        fail("mpm must be 'prefork', 'worker', or 'event' (got: ${mpm})")
    }

    package { "apache2-mpm-${mpm}":
        ensure => present,
    }

    if $mpm != 'prefork' {
        # Threaded MPMs are not compatible with the PHP module.
        apache::mod_conf { 'php5':
            ensure => absent,
            before => Exec['select_apache2_mpm'],
        }
    }

    file { "/etc/apache2/mods-available/mpm_${mpm}.load":
        ensure  => file,
        require => Package['apache2', "apache2-mpm-${mpm}"],
    }

    exec { 'select_apache2_mpm':
        command => "/usr/sbin/a2dismod -q `/usr/bin/basename mpm_*.load .load`; /usr/sbin/a2enmod mpm_${mpm}",
        creates => "/etc/apache2/mods-enabled/mpm_${mpm}.load",
        require => File["/etc/apache2/mods-available/mpm_${mpm}.load"],
        notify  => Service['apache2'],
    }

    Package["apache2-mpm-${mpm}"] -> Apache::Mod_conf <| |>
}
