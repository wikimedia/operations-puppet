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

    file { '/etc/default/cpufrequtils':
        content => "GOVERNOR=${governor}\n",
        notify  => Exec['set_cpufreq_governor'],
    }

    exec { 'set_cpufreq_governor':
        command => '/etc/init.d/cpufrequtils restart',
        unless  => "/usr/bin/cpufreq-info -p | /bin/grep -wq ${governor}",
    }
}
