# == Class: apache::mpm
#
# This class allows you to select an Apache Multi-Processing Module
# (or MPM). MPMs are mutually exclusive; you can only enable one.
# The MPMs available for you to choose from are prefork, worker, and
# event.
#
# Worker and event scale better, but they don't work with any modules
# which are not thread-safe, like PHP.
#
# See <http://httpd.apache.org/docs/current/mpm.html> for details.
#
# === Parameters
#
# [*mpm*]
#   Name of the chosen MPM. Must be 'prefork', 'worker', or 'event'.
#   The default is 'prefork'.
#
class apache::mpm( $mpm = 'prefork' ) {
    include ::apache

    $available_mpms = ['prefork', 'worker', 'event']
    if ! member($available_mpms, $mpm) {
        fail('mpm must be prefork, worker or event')
    }

    $selected_mod = "mpm_${mpm}"
    $selected_pkg = "apache2-mpm-${mpm}"
    $selected_cfg = "/etc/apache2/mods-available/mpm_${mpm}.load"

    $rejected_mpms = reject($available_mpms, $mpm)
    $rejected_mods = prefix($rejected_mpms, 'mpm_')

    if $mpm != 'prefork' {
        # mod_php5 is unsafe for threaded MPMs
        apache::mod_conf { 'php5':
            ensure => absent,
            before => Apache::Mod_conf[$selected_mod],
        }
    }

    apache::mod_conf { $rejected_mods:
        ensure => absent,
    }

    #Those are not needed in modern apache packages.
    if os_version('ubuntu < trusty') {
        package { $selected_pkg:
            ensure => present,
            before => File[$selected_cfg],
        }
    }

    file { $selected_cfg:
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        before => Apache::Mod_conf[$selected_mod],
    }

    apache::mod_conf { $selected_mod:
        ensure => present,
        notify => Exec['apache2_test_config_and_restart'],
    }
}
