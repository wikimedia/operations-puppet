# == Class: httpd::mpm
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
class httpd::mpm(
    Enum['prefork', 'event', 'worker'] $mpm = 'worker',
    Optional[String] $source = undef,
) {
    require_package('apache2')
    $selected_mod = "mpm_${mpm}"
    $available_mpms = ['prefork', 'worker', 'event']

    # mod_php5 is unsafe for threaded MPMs
    if $mpm != 'prefork' {
        if os_version('debian >= buster') {
          $php_version = 'php7.1'
        } elsif os_version('debian == stretch') {
          $php_version = 'php7'
        } else {
          $php_version = 'php5'
        }
        httpd::mod_conf { $php_version:
            ensure => absent,
            before => Httpd::Mod_conf[$selected_mod],
        }
    }

    # Module config
    file { "/etc/apache2/mods-available/mpm_${mpm}.load":
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    if $source {
        file { "/etc/apache2/mods-available/mpm_${mpm}.conf":
            ensure => present,
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => $source,
        }
    }

    # Disable the other mpms, enable the selected one.
    $rejected_mpms = prefix(reject($available_mpms, $mpm), 'mpm_')
    httpd::mod_conf { $rejected_mpms:
        ensure => absent,
    }

    httpd::mod_conf { "mpm_${mpm}":
        ensure => present,
        notify => Exec['apache2_test_config_and_restart']
    }
}
