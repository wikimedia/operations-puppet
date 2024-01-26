# SPDX-License-Identifier: Apache-2.0
define interface::post_up_command(
    String[1]      $interface,
    String[1]      $command,
    Wmflib::Ensure $ensure = 'present',
) {
    if $ensure == 'absent' {
        file_line { "rm_${interface}_${title}":
            ensure            => absent,
            path              => '/etc/network/interfaces',
            match             => "post-up ${command}",
            match_for_absence => true,
        }
    } else {
        # Use augeas to add an 'post-up' command to the interface
        augeas { "${interface}_${title}":
            incl    => '/etc/network/interfaces',
            lens    => 'Interfaces.lns',
            context => "/files/etc/network/interfaces/*[. = '${interface}']",
            changes => "set post-up[last()+1] '${command}'",
            onlyif  => "match post-up[. = '${command}'] size == 0";
        }
    }
}
