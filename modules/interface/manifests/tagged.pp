# SPDX-License-Identifier: Apache-2.0
define interface::tagged (
    String[1]                               $base_interface,
    Network::VLANTag                        $vlan_id,
    Optional[Stdlib::IP::Address::Nosubnet] $address = undef,
    Optional[Network::Netmask]              $netmask = undef,
    Enum['inet', 'inet6']                   $family  = 'inet',
    String[1]                               $method  = 'static',
    Optional[String[1]]                     $up      = undef,
    Optional[String[1]]                     $down    = undef,
    Boolean                                 $remove  = false,
) {
    ensure_packages('vlan')

    $intf = "vlan${vlan_id}"

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

    if $remove {
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
                "set iface[. = '${intf}']/vlan-raw-device ${base_interface}",
            ].delete('')
    }

    if $remove {
        exec { "/sbin/ifdown ${intf}":
            before => Augeas[$intf],
            onlyif => "/sbin/ifquery ${intf}",
        }
    }

    # Use augeas
    augeas { $intf:
        incl    => '/etc/network/interfaces',
        lens    => 'Interfaces.lns',
        context => '/files/etc/network/interfaces/',
        changes => $augeas_cmd,
    }

    if !$remove {
        exec { "/sbin/ifup ${intf}":
            require     => Package['vlan'],
            subscribe   => Augeas[$intf],
            refreshonly => true,
            tag         => "interface-create-${intf}",
        }
    }
}
