# SPDX-License-Identifier: Apache-2.0
define interface::up_command($interface, $command) {
    # Use augeas to add an 'up' command to the interface
    augeas { "${interface}_${title}":
        incl    => '/etc/network/interfaces',
        lens    => 'Interfaces.lns',
        context => "/files/etc/network/interfaces/*[. = '${interface}']",
        changes => "set up[last()+1] '${command}'",
        onlyif  => "match up[. = '${command}'] size == 0";
    }
}
