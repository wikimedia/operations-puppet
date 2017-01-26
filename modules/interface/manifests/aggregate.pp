define interface::aggregate_member($master) {
    require_package('ifenslave-2.6')

    $interface = $title

    augeas { "aggregate member ${interface}":
        context => '/files/etc/network/interfaces/',
        changes => [
                "set auto[./1 = '${interface}']/1 '${interface}'",
                "set iface[. = '${interface}'] '${interface}'",
                "set iface[. = '${interface}']/family 'inet'",
                "set iface[. = '${interface}']/method 'manual'",
        ],
        notify  => Exec["ifup ${interface}"],
    }

    exec { "ifup ${interface}":
        command     => "/sbin/ifup --force ${interface}; /sbin/ip link set dev ${interface} up",
        require     => Augeas["aggregate member ${interface}"],
        refreshonly => true,
    }
}

define interface::aggregate($orig_interface=undef, $members=[], $lacp_rate='fast', $hash_policy='layer2+3') {
    require_package('ifenslave-2.6')

    # Use the definition title as the destination (aggregated) interface
    $aggr_interface = $title

    if $orig_interface != '' {
        # Convert an existing interface, e.g. from eth0 to bond0
        $augeas_changes = [
            "set auto[./1 = '${orig_interface}']/1 '${aggr_interface}'",
            "set iface[. = '${orig_interface}'] '${aggr_interface}'",
        ]

        # Bring down the old interface after conversion
        exec { "ip addr flush dev ${orig_interface}":
            command     => "/sbin/ip addr flush dev ${orig_interface}",
            before      => Exec["ifup ${aggr_interface}"],
            subscribe   => Augeas["create ${aggr_interface}"],
            refreshonly => true,
            notify      => Exec["ifup ${aggr_interface}"],
        }
    } else {
        $augeas_changes = [
            "set auto[./1 = '${aggr_interface}']/1 '${aggr_interface}'",
            "set iface[. = '${aggr_interface}'] '${aggr_interface}'",
            "set iface[. = '${aggr_interface}']/family 'inet'",
            "set iface[. = '${aggr_interface}']/method 'manual'",
        ]
    }

    augeas { "create ${aggr_interface}":
        context => '/files/etc/network/interfaces/',
        changes => $augeas_changes,
        onlyif  => "match iface[. = '${aggr_interface}'] size == 0",
        notify  => Exec["ifup ${aggr_interface}"],
    }

    augeas { "configure ${aggr_interface}":
        require => Augeas["create ${aggr_interface}"],
        context => '/files/etc/network/interfaces/',
        changes => [
            inline_template("set iface[. = '<%= aggr_interface %>']/bond-slaves '<%= members.join(' ') %>"),
            "set iface[. = '${aggr_interface}']/bond-mode '802.3ad'",
            "set iface[. = '${aggr_interface}']/bond-lacp-rate '${lacp_rate}'",
            "set iface[. = '${aggr_interface}']/bond-miimon '100'",
            "set iface[. = '${aggr_interface}']/bond-xmit-hash-policy '${hash_policy}'",
        ],
        notify  => Exec["ifup ${aggr_interface}"],
    }

    # Define all aggregate members
    interface::aggregate_member{ $members:
        require => Augeas["create ${aggr_interface}"],
        master  => $aggr_interface,
        notify  => Exec["ifup ${aggr_interface}"],
    }

    # Bring up the new interface
    exec { "ifup ${aggr_interface}":
        command     => "/sbin/ifup --force ${aggr_interface}",
        require     => Interface::Aggregate_member[$members],
        refreshonly => true,
    }
}
