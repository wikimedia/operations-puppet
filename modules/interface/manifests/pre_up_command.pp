# SPDX-License-Identifier: Apache-2.0
define interface::pre_up_command($interface, $command) {
    # Use augeas to add an 'pre-up' command to the interface
    augeas { "${interface}_${title}":
        context => "/files/etc/network/interfaces/*[. = '${interface}']",
        changes => "set pre-up[last()+1] '${command}'",
        onlyif  => "match pre-up[. = '${command}'] size == 0";
    }
}
