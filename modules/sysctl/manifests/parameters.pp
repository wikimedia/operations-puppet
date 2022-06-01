# SPDX-License-Identifier: Apache-2.0
# == Define: sysctl::parameters
#
# This custom resource lets you specify sysctl parameters using a Puppet
# hash, set as the 'values' parameter.
#
# === Parameters
#
# [*values*]
#   A hash that maps kernel parameter names to their desire value.
#
# [*priority*]
#   A numeric value in range 60 - 99. In case of conflict, files with a
#   higher priority override files with a lower priority. Debian
#   reserves 0 - 59 for sysctl settings that are bundled with individual
#   packages. The default is 70. Values in 60 - 69 should be reserved
#   for cluster-wide defaults that should always have a lower priority
#   than role-specific customizations.
#
#   If you're not sure, leave this unspecified. The default value of 60
#   should suit most cases.
#
# === Examples
#
#  sysctl::parameters { 'swift_performance':
#    values   => {
#      'net.ipv4.tcp_tw_recycle' => '1',  # disable TIME_WAIT
#      'net.ipv4.tcp_tw_reuse'   => '1',
#    },
#    priority => 90,
#  }
#
define sysctl::parameters(
    $values,
    $ensure   = present,
    $priority = 70
) {
    sysctl::conffile { $title:
        ensure   => $ensure,
        content  => template('sysctl/sysctl.conf.erb'),
        priority => $priority,
    }
}
