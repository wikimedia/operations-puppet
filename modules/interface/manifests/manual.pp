# SPDX-License-Identifier: Apache-2.0
define interface::manual(
  $interface,
  $family='inet',
  Wmflib::Ensure $ensure='present'
) {
    # Use augeas to create a new manually setup interface with allow-hotplug
    $augeas_cmd = [ "set allow-hotplug[./1 = '${interface}']/1 '${interface}'",
            "set iface[. = '${interface}'] '${interface}'",
            "set iface[. = '${interface}']/family '${family}'",
            "set iface[. = '${interface}']/method 'manual'",
    ]

    if ensure == 'absent' {
        file_line { "rm_${interface}_manual":
            ensure            => absent,
            match             => "iface ${interface} ${family} manual",
            match_for_absence => true,
        }
        file_line { "rm_hotplug_${interface}":
            ensure            => absent,
            match             => "allow-hotplug ${interface}",
            match_for_absence => true,
        }
    } else {
        augeas { "${interface}_manual":
            context => '/files/etc/network/interfaces',
            changes => $augeas_cmd;
        }
    }
}
