# SPDX-License-Identifier: Apache-2.0
# Add clsact qdisc to any existent interface
define interface::clsact(
    String $interface,
    Wmflib::Ensure $ensure = 'present',
) {
    $tc_add_cmd = "/usr/sbin/tc qdisc add dev ${interface} clsact"
    $tc_del_cmd = "/usr/sbin/tc qdisc del dev ${interface} clsact"

    interface::post_up_command { "clsact_${interface}":
        ensure    => $ensure,
        interface => $interface,
        command   => $tc_add_cmd,
    }

    if $ensure == 'absent' {
        exec { $tc_del_cmd:
            onlyif => "/usr/sbin/tc qdisc show dev ${interface} | grep -q clsact",
        }
    } else {
        # Add clsact manually as well
        exec { $tc_add_cmd:
            unless => "/usr/sbin/tc qdisc show dev ${interface} | grep -q clsact",
        }
    }
}
