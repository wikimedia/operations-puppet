define interface::add_ip6_mapped($interface=undef, $ipv4_address=undef) {
    if ! $interface {
        $all_interfaces = split($::interfaces, ',')
        $intf = $all_interfaces[0]
    }
    else {
        $intf = $interface
    }

    if ! member(split($::interfaces, ','), $intf) {
        warning("Not adding IPv6 address to ${intf} because this interface does not exist!")
    }
    else {
        if ! $ipv4_address {
            $ip4_address = "::${::ipaddress}"
        }
        else {
            $ip4_address = "::${ipv4_address}"
        }

        $ipv6_address = inline_template("<%= require 'ipaddr'; (IPAddr.new(scope.lookupvar(\"::ipaddress6_${intf}\")).mask(64) | IPAddr.new(ip4_address.gsub('.', ':'))).to_s() %>")

        interface::ip { $title:
            interface => $intf,
            address   => $ipv6_address,
            prefixlen => '64'
        }
    }
}
