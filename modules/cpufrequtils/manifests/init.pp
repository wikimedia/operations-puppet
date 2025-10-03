# SPDX-License-Identifier: Apache-2.0
# @summary
#   This class installs the cpufrequtils package and ensures a configured
#   CPU frequency governor is set.
#   From Trixie onward Debian ships the linux-cpupower package, but
#   we keep the class name for convenience.
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
    Wmflib::Ensure $ensure = 'present',
    String $governor = 'performance'
) {
    unless $facts['is_virtual'] {
        if debian::codename::ge('trixie') {
            ensure_packages('linux-cpupower')

            # Please note that Debian upstream is currently (Oct 2025) evaluating
            # to include the systemd unit and config files in the package itself.
            # See https://bugs-devel.debian.org/cgi-bin/bugreport.cgi?bug=894906
            # for more info.
            file { '/etc/default/cpupower':
                content => "GOVERNOR=${governor}\n",
                require => Package['linux-cpupower'],
            }

            file { '/usr/libexec/cpupower':
                ensure => $ensure,
                source => 'puppet:///modules/cpufrequtils/cpupower.sh',
            }

            systemd::service { 'cpupower':
                ensure  => $ensure,
                content => systemd_template('cpupower'),
                restart => true,
            }

            # cpupower is a systemd unit where RemainAfterExit=yes is set.
            # When the service resource was trying to "start" it, systemd would
            # find it as already running, thus not changing the governor.
            # cpupower will be reloaded if this is not the governor we are looking for
            exec { 'cpupower_reload':
                unless  => "/usr/bin/cpupower frequency-info -p | /bin/grep -wq ${governor}",
                command => '/usr/bin/systemctl restart cpupower',
                require => File['/etc/default/cpupower']
            }

        } else {
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
}
