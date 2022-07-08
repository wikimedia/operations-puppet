# SPDX-License-Identifier: Apache-2.0
# Definition: interface::setting
#
# Change an interface setting via augeas in /etc/network/interfaces

define interface::setting($interface, $setting, $value) {
    augeas { "${interface}_${title}":
        context => "/files/etc/network/interfaces/*[. = '${interface}' and family = 'inet']",
        changes => "set ${setting} '${value}'",
    }
}
