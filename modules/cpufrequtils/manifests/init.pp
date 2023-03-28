# SPDX-License-Identifier: Apache-2.0
# @summary
#   This class installs the cpufrequtils package and ensures a configured
#   CPU frequency governor is set.
# @param governor
#   Which governor to use. Defaults to 'performance'. Run 'cpufreq-info -g'
#   to obtain a list of available governors.
# @example
#
#  class { 'cpufrequtils':
#    governor => 'powersave',
#  }
#
class cpufrequtils(
    String $governor = 'performance'
) {
    unless $facts['is_virtual'] {
        ensure_packages('cpufrequtils')

        file { '/etc/default/cpufrequtils':
            content => "GOVERNOR=${governor}\n",
            require => Package['cpufrequtils'],
        }

        service { 'cpufrequtils':
            ensure => 'running',
            enable => true,
        }
        # cpufrequtils is a systemd generator where RemainAfterExit=yes is set.
        # When the service resource was trying to "start" it, systemd would
        # find it as already running, thus not changing the governor.
        # cpufrequtils will be reloaded if this is not the governor we are looking for
        exec { 'cpufrequtils_reload':
            unless  => "/usr/bin/cpufreq-info -p | /bin/grep -wq ${governor}",
            command => '/usr/bin/systemctl reload cpufrequtils',
            require => File['/etc/default/cpufrequtils']
        }

    }
}
