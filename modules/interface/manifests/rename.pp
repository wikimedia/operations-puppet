# SPDX-License-Identifier: Apache-2.0

# Renames network interface with a given MAC address.
# The title of the resource is the new interface name.

# This is useful if you ever encounter a NIC name with string length > IFNAMSIZ (16)

# This method can be extended to rename NICs in a more fine-grained fashion,
# see systemd.link(5) for reference

define interface::rename (
    Stdlib::MAC $mac,
) {
    $new_name = $title

    # NOTE: I don't think there is need to notify or reload any service.
    # this will be read by systemd-udev at boot time. I may be wrong tho.

    file { "/etc/systemd/network/10-persistent-net-${new_name}.link":
        ensure  => 'present',
        content => template('interface/rename.link.erb'),
    }
}
