define interface::tagged($base_interface, $vlan_id, $address=undef, $netmask=undef, $family='inet', $method='static', $up=undef, $down=undef, $remove=undef) {
    require_package('vlan')

    $intf_fl = "${base_interface}.${vlan_id}"

    # make sure that the interface name doesn't exceed IFNAMSIZ (T209707)
    if os_version('debian == stretch') {
        $intf = $intf_fl[-15, 15]
    } else {
        $intf = $intf_fl
    }

    if $address {
        $addr_cmd = "set iface[. = '${intf}']/address '${address}'"
    } else {
        $addr_cmd = ''
    }

    if $netmask {
        $netmask_cmd = "set iface[. = '${intf}']/netmask '${netmask}'"
    } else {
        $netmask_cmd = ''
    }

    if $up {
        $up_cmd = "set iface[. = '${intf}']/up '${up}'"
    } else {
        $up_cmd = ''
    }
    if $down {
        $down_cmd = "set iface[. = '${intf}']/down '${down}'"
    } else {
        $down_cmd = ''
    }

    if $remove == true {
        $augeas_cmd = [ "rm auto[./1 = '${intf}']",
                "rm iface[. = '${intf}']"
            ]
    } else {
        $augeas_cmd = [ "set auto[./1 = '${intf}']/1 '${intf}'",
                "set iface[. = '${intf}'] '${intf}'",
                "set iface[. = '${intf}']/family '${family}'",
                "set iface[. = '${intf}']/method '${method}'",
                $addr_cmd,
                $netmask_cmd,
                $up_cmd,
                $down_cmd,
            ]
    }

    if $remove == true {
        exec { "/sbin/ifdown ${intf}":
            before => Augeas[$intf],
        }
    }

    # Use augeas
    augeas { $intf:
        context => '/files/etc/network/interfaces/',
        changes => $augeas_cmd;
    }

    if $remove != true {
        exec { "/sbin/ifup ${intf}":
            subscribe   => Augeas[$intf],
            refreshonly => true,
        }
    }
}
