define interface::manual($interface, $family='inet') {
    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '10.04') >= 0 {
        # Use augeas to create a new manually setup interface
        $augeas_cmd = [ "set auto[./1 = '${interface}']/1 '${interface}'",
                "set iface[. = '${interface}'] '${interface}'",
                "set iface[. = '${interface}']/family '${family}'",
                "set iface[. = '${interface}']/method 'manual'",
        ]

        augeas { "${interface}_manual":
            context => '/files/etc/network/interfaces',
            changes => $augeas_cmd;
        }
    }
}
