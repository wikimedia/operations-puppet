define interface::manual($interface, $family='inet') {
    # Use augeas to create a new manually setup interface with allow-hotplug
    $augeas_cmd = [ "set allow-hotplug[./1 = '${interface}']/1 '${interface}'",
            "set iface[. = '${interface}'] '${interface}'",
            "set iface[. = '${interface}']/family '${family}'",
            "set iface[. = '${interface}']/method 'manual'",
    ]

    augeas { "${interface}_manual":
        context => '/files/etc/network/interfaces',
        changes => $augeas_cmd;
    }
}
