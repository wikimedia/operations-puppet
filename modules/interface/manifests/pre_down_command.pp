# SPDX-License-Identifier: Apache-2.0
define interface::pre_down_command(
    String[1]      $interface,
    String[1]      $command,
    Wmflib::Ensure $ensure = 'present',
) {
    if $ensure == 'absent' {
        file_line { "rm_pre-down_${interface}_${title}":
            ensure            => absent,
            path              => '/etc/network/interfaces',
            match             => "pre-down ${command}",
            match_for_absence => true,
        }
    } else {
        # Use augeas to add an 'pre-down' command to the interface
        augeas { "pre-down_${interface}_${title}":
            incl    => '/etc/network/interfaces',
            lens    => 'Interfaces.lns',
            context => "/files/etc/network/interfaces/*[. = '${interface}']",
            changes => "set pre-down[last()+1] '${command}'",
            onlyif  => "match pre-down[. = '${command}'] size == 0";
        }
    }
}
