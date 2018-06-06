# Definition: interface::route
#
# Adds a static route for a defined prefix
#
# Parameters:
# - $address:
#   Destination address without the prefix
# - $nexthop:
#   Next hop used to reach the destination address
# - $interface:
#   Optional Exit interface
# - $mtu:
#   Optional MTU (lock) to use for that destination
# - $prefixlen:
#   Optional Destination's prefix
# - $options:
#   Optional Additional options
define interface::route($address, $nexthop, $interface=undef, $mtu=undef, $prefixlen='32', $options=undef) {
    $prefix = "${address}/${prefixlen}"
    $mtu_cmd = $mtu ? { undef => '', default => "mtu lock ${mtu}" }
    $interface_cmd = $interface ? { undef => '', default => "dev ${interface}" }

    $route_command = "ip route add ${prefix} via ${nexthop} ${mtu_cmd} ${options} ${interface_cmd}"
    # Insert the route
    # When a /32 prefix is present, 'ip route show' strips the /32
    exec { $route_command:
        path   => '/bin:/usr/bin',
        unless => "ip route show ${prefix} | grep -q ${address}",
    }
}
