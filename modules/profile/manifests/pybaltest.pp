class profile::pybaltest (
    Array[Stdlib::Host] $hosts = lookup('profile::pybaltest::hosts'),
) {
    firewall::service { 'pybaltest-http':
        proto  => 'tcp',
        port   => 80,
        srange => $hosts,
    }

    firewall::service { 'pybaltest-bgp':
        proto  => 'tcp',
        port   => 179,
        srange => $hosts,
    }

    # If the host considers itself as a router (IP forwarding enabled), it will
    # ignore all router advertisements, breaking IPv6 SLAAC. Accept Router
    # Advertisements even if forwarding is enabled.
    sysctl::parameters { 'accept-ra':
        values => {
            "net.ipv6.conf.${facts['interface_primary']}.accept_ra" => 2,
        },
    }

    # In bullseye, we install Pybal from component.
    if debian::codename::eq('bullseye') {
        apt::package_from_component { 'pybal':
            component => 'component/pybal',
        }
    }
}
