# SPDX-License-Identifier: Apache-2.0
# == Define: kmod::options
#
# Add options to the given module every time it is inserted into the kernel.
#
# === Parameters
#
# [*options*]
#   The options to add.
#
# === Example
#
# kmod::options { "nf_conntrack":
#     options => 'hashsize=32768',
# }
#
define kmod::options($options) {
    file { "/etc/modprobe.d/options-${name}.conf":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('kmod/options.conf.erb'),
    }
}
