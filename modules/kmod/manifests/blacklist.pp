# == Define: kmod::blacklist
#
# Blacklist the given Linux kernel modules.
#
# === Parameters
#
# [*modules*]
#   The list of module names to be blacklisted.
#
# === Example
#
# kmod::blacklist { "linux44":
#     modules => [ 'asn1_decoder', 'macsec' ],
# }
#
define kmod::blacklist($modules = [], $ensure = present) {
    file { "/etc/modprobe.d/blacklist-${name}.conf":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('kmod/blacklist.conf.erb'),
        notify  => Exec['update-initramfs'],
    }
}
