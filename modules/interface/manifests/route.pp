# SPDX-License-Identifier: Apache-2.0
# @summary Adds a static route for a defined prefix
# @param address Destination address without the prefix
# @param nexthop Next hop used to reach the destination address
# @param ipversion IPv4 or IPv6 route
# @param interface Exit interface
# @param mtu MTU (lock) to use for that destination
# @param prefixlen Destination's prefix
# @param table Routing table to use for this route
# @param persist Create a post-up entry in /etc/network/interfaces to persist the route
define interface::route(
    Interface::RouteTarget        $address,
    Stdlib::IP::Address::Nosubnet $nexthop,
    String[1]                     $interface = $facts['networking']['primary'],
    Boolean                       $persist   = false,
    Optional[Integer[512,1500]]   $mtu       = undef,
    Optional[Integer[0,128]]      $prefixlen = undef,
    Optional[String[1]]           $table     = undef,
) {
    $nexthop_version = wmflib::ip_family($nexthop)
    $ipversion = $address ? {
        'default' => $nexthop_version,
        default   => wmflib::ip_family($address),
    }

    if $ipversion != $nexthop_version {
        fail("\$address (${address}) and \$nexthop (${nexthop}) need to use the same ip family")
    }

    if $address == 'default' {
        $prefix = 'default'
    } else {
        $_prefixlen = $prefixlen.lest || {
            if $ipversion == 4 { 32 } else { 128 }
        }
        $prefix = "${address}/${_prefixlen}"
    }

    $mtu_cmd = $mtu.then |$x| { "mtu lock ${x}" }
    $int_cmd = $interface.then |$x| { "dev ${x}" }
    $table_cmd = $table.then |$x| { " table ${x}" }
    $table_require = $table.then |$x| { Interface::Routing_table[$x] }
    $v6switch = ($ipversion == 6).bool2str('-6', '')
    $route_cmd = "ip ${v6switch} route"

    # We split and join to get rid of excessive whitespace
    $add_command = "${route_cmd} add ${prefix} via ${nexthop} ${mtu_cmd} ${int_cmd}${table_cmd}"
                    .split(/\s+/)
                    .join(' ')
    # Insert the route, same command for v6 and v4
    # But show command needs '-6' to display v6 routes
    # When a /32 or /128 prefix lenght is present, 'ip route show' strips it
    $show_command = "${route_cmd} show ${prefix}${table_cmd} | grep -q via"
    exec { $add_command:
        path    => '/bin:/usr/bin',
        unless  => $show_command,
        require => $table_require,
    }

    # if the interface is managed by Puppet, ensure it's created first
    Exec <| tag == "interface-create-${interface}" |>
        -> Exec[$add_command]

    # persisting the route is optional, but if you don't do it, it won't survive
    # a reboot of the server and the route will be missing until the next puppet run.
    if $persist {
        interface::post_up_command { "${title}_persist":
            interface => $interface,
            command   => $add_command,
        }
    }
}
