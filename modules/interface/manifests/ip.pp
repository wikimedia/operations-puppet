# Expects address without a length, like address => "208.80.152.10", prefixlen => "32"
define interface::ip($interface, $address, $prefixlen='32', $options) {
    $prefix = "${address}/${prefixlen}"
    if $options {
        $options_real = "${options} "
    } else {
        $options_real = ''
    }
    $ipaddr_command = "ip addr add ${prefix} ${options_real}dev ${interface}"

    # Use augeas to add an 'up' command to the interface
    augeas { "${interface}_${prefix}":
        context => "/files/etc/network/interfaces/*[. = '${interface}' and ./family = 'inet']",
        changes => "set up[last()+1] '${ipaddr_command}'",
        onlyif  => "match up[. = '${ipaddr_command}'] size == 0";
    }

    # Add the IP address manually as well
    exec { $ipaddr_command:
        path    => '/bin:/usr/bin',
        returns => [0, 2],
        unless  => "ip address show ${interface} | grep -q ${prefix}",
    }
}
