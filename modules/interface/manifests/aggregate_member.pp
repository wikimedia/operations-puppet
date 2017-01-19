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
        notify  => Exec["ifup ${interface}"]
    }

    exec { "ifup ${interface}":
        command     => "/sbin/ifup --force ${interface}; /sbin/ip link set dev ${interface} up",
        require     => Augeas["aggregate member ${interface}"],
        refreshonly => true
    }
}

