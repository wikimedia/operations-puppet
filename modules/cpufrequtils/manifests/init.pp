# SPDX-License-Identifier: Apache-2.0
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
    unless $facts['is_virtual'] {
        ensure_packages('cpufrequtils')

        file { '/etc/default/cpufrequtils':
            content => "GOVERNOR=${governor}\n",
            require => Package['cpufrequtils'],
            notify  => Service['cpufrequtils'],
        }

        service { 'cpufrequtils':
            ensure => 'running',
            enable => true,
            status => "/usr/bin/cpufreq-info -p | /bin/grep -wq ${governor}",
        }
    }
}
