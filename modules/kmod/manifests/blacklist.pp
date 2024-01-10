# SPDX-License-Identifier: Apache-2.0
# == Define: kmod::blacklist
#
# Blacklist the given Linux kernel modules.
#
# === Parameters
#
# [*ensure*]
#   Standard ensure parameter
# [*modules*]
#   The list of module names to be blacklisted.
# [*rmmod*]
#   A boolean to also remove the blacklisted module. Defaults to false for
#   compatibility reasons
#
# === Example
#
# kmod::blacklist { "linux44":
#     modules => [ 'asn1_decoder', 'macsec' ],
# }
#
define kmod::blacklist (
    Wmflib::Ensure $ensure = present,
    Array[String] $modules = [],
    Boolean $rmmod = false,
) {
    if $rmmod {
        $rmmod_args = join($modules, ' ')
        exec { "rmmod-${name}":
          command     => "/sbin/modprobe -r ${rmmod_args}",
          refreshonly => true,
        }
        $notify = [
          Exec['update-initramfs'],
          Exec["rmmod-${name}"],
        ]
    } else {
        $notify = [
          Exec['update-initramfs'],
        ]
    }
    file { "/etc/modprobe.d/blacklist-${name}.conf":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('kmod/blacklist.conf.erb'),
        notify  => $notify,
    }
}
