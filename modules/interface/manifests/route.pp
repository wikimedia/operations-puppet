# SPDX-License-Identifier: Apache-2.0
# Definition: interface::route
#
# Adds a static route for a defined prefix
#
# Parameters:
# - $address:
#   Destination address without the prefix
# - $nexthop:
#   Next hop used to reach the destination address
# - $ipversion:
#   IPv4 or IPv6 route
# - $interface:
#   Optional Exit interface
# - $mtu:
#   Optional MTU (lock) to use for that destination
# - $prefixlen:
#   Optional Destination's prefix
# - $options:
#   Optional Additional options
define interface::route($address, $nexthop, $ipversion=4, $interface=undef, $mtu=undef, $prefixlen=undef, $options=undef) {
    if $prefixlen == undef and $ipversion == 4 { # If v6 IP, host prefix lenght is 32
        $prefix = "${address}/32"
    }
    elsif $prefixlen == undef and $ipversion == 6 { # If v6 IP, host prefix lenght is 128,
        $prefix = "${address}/128"
    }
    elsif $prefixlen != undef { #otherwise use whatever defined
        $prefix = "${address}/${prefixlen}"
    }

    $mtu_cmd = $mtu ? { undef => '', default => "mtu lock ${mtu}" }
    $interface_cmd = $interface ? { undef => '', default => "dev ${interface}" }

    $route_command = "ip route add ${prefix} via ${nexthop} ${mtu_cmd} ${options} ${interface_cmd}"
    # Insert the route, same command for v6 and v4
    # But show command needs '-6' to display v6 routes
    # When a /32 or /128 prefix lenght is present, 'ip route show' strips it
    $v6switch = $ipversion ?  { 6 => '-6', 4 => '' }
    $show_command = "ip ${v6switch} route show ${prefix} | grep -q via"
    exec { $route_command:
        path   => '/bin:/usr/bin',
        unless => $show_command,
    }
}
