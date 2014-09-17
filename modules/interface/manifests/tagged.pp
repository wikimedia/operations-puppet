class interface::vlan-tools {
    package { 'vlan':
        ensure => latest,
    }
}

define interface::tagged($base_interface, $vlan_id, $address=undef, $netmask=undef, $family='inet', $method='static', $up=undef, $down=undef, $v6_token=false, $remove=undef) {
    require interface::vlan-tools

    $intf = "${base_interface}.${vlan_id}"

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

    if $v6_token {
        $v6_token_lower64 = regsubst($address, '\.', ':', 'G')
        $v6_token_addr = "::${v6_token_lower64}"
        $v6_token_cmd = "set iface[. = '${intf}']/up '/sbin/ip token set ${v6_token_addr} dev ${intf}'"
    } else {
        $v6_token_cmd = ''
    }

    if $remove == 'true' {
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
                $v6_token_cmd,
                $down_cmd,
            ]
    }

    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '10.04') >= 0 {
        if $remove == 'true' {
            exec { "/sbin/ifdown ${intf}":
                before => Augeas[$intf],
            }
        }

        # Use augeas
        augeas { $intf:
            context => '/files/etc/network/interfaces/',
            changes => $augeas_cmd;
        }

        if $remove != 'true' {
            exec { "/sbin/ifup ${intf}":
                subscribe => Augeas[$intf],
                refreshonly => true,
            }
        }
    }
}
