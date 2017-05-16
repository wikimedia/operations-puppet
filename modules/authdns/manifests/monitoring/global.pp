# == Class authdns::monitoring::global
# Monitoring checks for authdns, specific to Wikimedia setup
#

# This monitors the actual public listener IPs, regardless
#  of which authdns machines they're currently routed to.
# Obviously, its view will be limited to how they're routed
#  *from the monitoring machine*, which is imperfect but
#  better than nothing.
define authdns::monitoring::global($ipv4, $ipv6) {
    $hostlabel = $title # just for semantic clarity below

    @monitoring::host { "${hostlabel}_ipv4":
        ip_address => $ipv4,
    }

    @monitoring::host { "${hostlabel}_ipv6":
        ip_address => $ipv6,
    }

    @monitoring::service { "${hostlabel}_ipv4":
        host          => "${hostlabel}_ipv4",
        description   => 'AuthDNS IPv4',
        check_command => 'check_dns!www.wikipedia.org',
        critical      => true,
    }

    @monitoring::service { "${hostlabel}_ipv6":
        host          => "${hostlabel}_ipv6",
        description   => 'AuthDNS IPv6',
        check_command => 'check_dns!www.wikipedia.org',
        critical      => true,
    }
}
