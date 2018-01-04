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
    }

    # Could be notify=> above, but the exec only exists in base for jessie+...
    if os_version('debian >= jessie') {
        File["/etc/modprobe.d/blacklist-${name}.conf"] ~> Exec['update-initramfs']
    }
}
