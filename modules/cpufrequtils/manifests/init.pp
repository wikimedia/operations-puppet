# == Class: cpufrequtils
#
# This class installs the cpufrequtils package and ensures a configured
# CPU frequency governor is set.
#
# === Parameters
#
# [*governor*]
#   Which governor to use. Defaults to 'performance'. Run 'cpufreq-info -g'
#   to obtain a list of available governors.
#
# === Examples
#
#  class { 'cpufrequtils':
#    governor => 'powersave',
#  }
#
class cpufrequtils( $governor = 'performance' ) {
    require_package('cpufrequtils')

    service { 'cpufrequtils':
        enable => true,
    }

    # Ubuntu's default initscripts package includes a service called "ondemand"
    #   which is a one-shot action invoked at startup which sleeps 60 seconds
    #   and then sets all CPUs to the ondemand governor, thus undoing the work
    #   of cpufrequtils. Debian has no such stupidity.
    if $::operatingsystem == 'Ubuntu' {
        service { 'ondemand':
            enable => false,
        }
    }

    file { '/etc/default/cpufrequtils':
        content => "GOVERNOR=${governor}\n",
        notify  => Exec['set_cpufreq_governor'],
    }

    exec { 'set_cpufreq_governor':
        command => '/etc/init.d/cpufrequtils restart',
        unless  => "/usr/bin/cpufreq-info -p | /bin/grep -wq ${governor}",
    }
}
