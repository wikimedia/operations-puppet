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
# - $persist:
#   Optional: Create a post-up entry in /etc/network/interfaces to persist the route
define interface::route(
    $address,
    $nexthop,
    $ipversion=4,
    $interface=undef,
    $mtu=undef,
    $prefixlen=undef,
    $options=undef,
    Optional[Boolean] $persist = false,
) {
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

    # persisting the route is optional, but if you don't do it, it won't survive
    # a reboot of the server and the route will be missing until the next puppet run.
    if $persist {
        if $interface == undef {
            fail('interface::route: missing target interface to persist')
        }

        interface::post_up_command { "${title}_persist":
            interface => $interface,
            command   => $route_command,
        }
    }
}
