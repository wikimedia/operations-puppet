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
# [*module*]
#   Optional module name, if supplied a udev rule is added to update the sysctl
#   values when the module is added. Systemd's systemd-sysctl.service runs
#   early in boot. When it runs there is no guarantee that all kernel modules,
#   of which we have sysctls set, are loaded. As a result certain sysctls, such
#   as `net.netfilter.nf_conntrack_max`, are never set, since their module has
#   not been loaded yet. Instead, use a udev trigger to update the sysctls.
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
#  # With module name to create udev rule
#  sysctl::parameters { 'kdc_conntrack':
#      values   => {
#          'net.netfilter.nf_conntrack_max' => 524288,
#      },
#      priority => 75,
#      module   => 'nf_conntrack',
#  }
define sysctl::parameters(
    $values,
    $ensure   = present,
    $priority = 70,
    $module   = undef,
) {
    sysctl::conffile { $title:
        ensure   => $ensure,
        content  => template('sysctl/sysctl.conf.erb'),
        priority => $priority,
    }
    if $module {
        $prefix = sysctl::shared_prefix($values)
        if $prefix == '' {
            fail(@(EOF/L))
            "When using the module param, the supplied sysctls must \
            share a common prefix, to avoid reloading all sysctls"
            | EOF
        }
        $udev_title = regsubst($title, '\W', '-', 'G')
        udev::rule { $udev_title:
            content  => @("EOF"),
                ACTION=="add", SUBSYSTEM=="module", KERNEL=="${module}", \
                    RUN+="/usr/lib/systemd/systemd-sysctl --prefix ${prefix}"
                | EOF
            priority => $priority,
        }
    }
}
