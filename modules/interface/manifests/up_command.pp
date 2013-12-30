define interface::up_command($interface, $command) {
    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '10.04') >= 0 {
        # Use augeas to add an 'up' command to the interface
        augeas { "${interface}_${title}":
            context => "/files/etc/network/interfaces/*[. = '${interface}']",
            changes => "set up[last()+1] '${command}'",
            onlyif  => "match up[. = '${command}'] size == 0";
        }
    }
}
