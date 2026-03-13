# SPDX-License-Identifier: Apache-2.0
# == Class profile::base::reboot_unattended
#
# This class can be used mark a host for unattended reboots. This profile
# just marks the host but no actual reboot will be executed. The reboot
# happens in a dedicated cookbook.
#
# @param $allow mark the host and allow unattended reboots, default false
class profile::base::reboot_unattended (
    Boolean $allow = lookup('profile::base::reboot_unattended::allow', { default_value => false }),
) {
    $ensure_file = $allow ? {
      true    => file,
      default => absent,
    }

    file { '/etc/wikimedia/reboot-unattended':
        ensure  => 'directory',
        mode    => '0644',
        recurse => true,
        purge   => true,
    }

    file { '/etc/wikimedia/reboot-unattended/allow.conf':
        ensure  => $ensure_file,
        mode    => '0644',
        content => "allow\n",
    }
}

