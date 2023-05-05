# SPDX-License-Identifier: Apache-2.0
define interface::post_up_command($interface, $command) {
    # Use augeas to add an 'post-up' command to the interface
    augeas { "${interface}_${title}":
        context => "/files/etc/network/interfaces/*[. = '${interface}']",
        changes => "set post-up[last()+1] '${command}'",
        onlyif  => "match post-up[. = '${command}'] size == 0";
    }
}
