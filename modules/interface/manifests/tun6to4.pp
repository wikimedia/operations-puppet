define interface::tun6to4($remove=undef) {
    if $remove == true {
        $augeas_cmd = [ "rm auto[./1 = 'tun6to4']",
                "rm iface[. = 'tun6to4']",
            ]
    } else {
        $augeas_cmd = [ "set auto[./1 = 'tun6to4']/1 'tun6to4'",
                "set iface[. = 'tun6to4'] 'tun6to4'",
                "set iface[. = 'tun6to4']/family 'inet6'",
                "set iface[. = 'tun6to4']/method 'v4tunnel'",
                "set iface[. = 'tun6to4']/endpoint 'any'",
                "set iface[. = 'tun6to4']/local '192.88.99.1'",
                "set iface[. = 'tun6to4']/ttl '64'",
                "set iface[. = 'tun6to4']/pre-up 'ip address add 192.88.99.1/32 dev lo label lo:6to4'",
                "set iface[. = 'tun6to4']/down 'ip address del 192.88.99.1/32 dev lo label lo:6to4'",
                "set iface[. = 'tun6to4']/up 'ip -6 route add 2002::/16 dev \$IFACE'",
            ]
    }

    if $remove == true {
        exec { '/sbin/ifdown tun6to4':
            before => Augeas['tun6to4'],
        }
    }

    # Use augeas
    augeas { 'tun6to4':
        context => '/files/etc/network/interfaces/',
        changes => $augeas_cmd,
    }

    if $remove != true {
        exec { '/sbin/ifup tun6to4':
            require => Augeas['tun6to4'],
        }
    }
}
