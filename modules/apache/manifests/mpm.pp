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
# [*source*]
#   A puppet URL to a file containing the mpm specific configuration required.
#   Defaults to undef.
#
class apache::mpm(
    $mpm = 'prefork',
    $source = undef,
) {
    include ::apache

    $available_mpms = ['prefork', 'worker', 'event']
    if ! member($available_mpms, $mpm) {
        fail('mpm must be prefork, worker or event')
    }

    $selected_mod = "mpm_${mpm}"
    $selected_cfg = "/etc/apache2/mods-available/mpm_${mpm}.load"
    $mpm_conf = "/etc/apache2/mods-available/mpm_${mpm}.conf"

    $rejected_mpms = reject($available_mpms, $mpm)
    $rejected_mods = prefix($rejected_mpms, 'mpm_')

    if $mpm != 'prefork' {
        if os_version('debian >= buster') {
          $php_version = 'php7.1'
        } elsif os_version('debian == stretch') {
          $php_version = 'php7'
        } else {
          $php_version = 'php5'
        }

        # mod_php5 or 7 or 7.1 is unsafe for threaded MPMs
        apache::mod_conf { $php_version:
            ensure => absent,
            before => Apache::Mod_conf[$selected_mod],
    }

    apache::mod_conf { $rejected_mods:
        ensure => absent,
    }

    file { $selected_cfg:
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        before  => Apache::Mod_conf[$selected_mod],
        require => Package['apache2'],
    }

    if $source {
        file { $mpm_conf:
            ensure  => file,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            source  => $source,
            before  => Apache::Mod_conf[$selected_mod],
            require => Package['apache2'],
        }
    }

    apache::mod_conf { $selected_mod:
        ensure  => present,
        notify  => Exec['apache2_test_config_and_restart'],
        require => Package['apache2'],
    }
}
