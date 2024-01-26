# SPDX-License-Identifier: Apache-2.0
# IPIP device creation for load balancers and realservers
# we don't set an endpoint so we cannot leverage the "tunnel" method from /etc/network/interfaces
define interface::ipip(
  String $interface,
  Enum['inet', 'inet6'] $family='inet',
  Optional[Stdlib::IP::Address::V4] $address=undef,
  Wmflib::Ensure $ensure = 'present',
) {
    if $family == 'inet' and !defined('$address') {
        fail('inet family requires an address')
    }

    interface::manual { $title:
        ensure    => $ensure,
        interface => $interface,
        family    => $family,
    }

    # provide an ip link cmd
    $tunnel_type = $family ? {
      'inet'  => 'ipip',
      'inet6' => 'ip6tnl',
    }
    $ip_link_add = "ip link add name ${interface} type ${tunnel_type} external"
    $ip_link_up = "ip link set up dev ${interface}"

    if $ensure == 'absent' { # Remove the interface
        if $family == 'inet' {
            interface::ip{ "${title} ipv4":
                ensure    => absent,
                interface => $interface,
                address   => $address,
                prefixlen => 32,
            }
        }

        $ip_link_del = "ip link del dev ${interface}"

        file_line { "rm_${interface}_set_up":
            ensure            => absent,
            path              => '/etc/network/interfaces',
            match             => $ip_link_up,
            match_for_absence => true,
        }
        file_line { "rm_${interface}_add_up":
            ensure            => absent,
            path              => '/etc/network/interfaces',
            match             => $ip_link_add,
            match_for_absence => true,
        }

        exec { $ip_link_del:
            path    => '/bin:/usr/bin',
            returns => [0, 2],
            onlyif  => "ip link show ${interface}",
        }
    } else { # Add the interface

        augeas { "${interface}_add_up":
            incl    => '/etc/network/interfaces',
            lens    => 'Interfaces.lns',
            context => "/files/etc/network/interfaces/*[. = '${interface}' and ./family = '${family}']",
            changes => "set up[last()+1] '${ip_link_add}'",
            onlyif  => "match up[. = '${ip_link_add}'] size == 0",
            require => Interface::Manual[$title],
        }

        augeas { "${interface}_set_up":
            incl    => '/etc/network/interfaces',
            lens    => 'Interfaces.lns',
            context => "/files/etc/network/interfaces/*[. = '${interface}' and ./family = '${family}']",
            changes => "set up[last()+1] '${ip_link_up}'",
            onlyif  => "match up[. = '${ip_link_up}'] size == 0",
            require => Augeas["${interface}_add_up"],
        }

        # Create the device manually as well
        exec { $ip_link_add:
            path    => '/bin:/usr/bin',
            returns => [0, 2],
            unless  => "ip link show ${interface}",
        }

        exec { $ip_link_up:
            path    => '/bin:/usr/bin',
            returns => [0, 2],
            unless  => "ip link show ${interface} | grep -q UP",
        }

        # Assign the provided address for IPv4 interfaces
        if $family == 'inet' {
            interface::ip{ "${title} ipv4":
                interface => $interface,
                address   => $address,
                prefixlen => 32,
                require   => Augeas["${interface}_set_up"],
            }
        }
    }
}
