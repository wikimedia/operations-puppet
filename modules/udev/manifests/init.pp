# SPDX-License-Identifier: Apache-2.0
class udev {
    exec { 'udev_reload':
        command     => '/usr/bin/udevadm control --reload && /usr/bin/udevadm trigger',
        refreshonly => true,
    }
}
