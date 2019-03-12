# == Class authdns::monitoring::global
# Monitoring checks for authdns, specific to Wikimedia setup
#

# This monitors the actual public listener IPs, regardless
#  of which authdns machines they're currently routed to.
# Obviously, its view will be limited to how they're routed
#  *from the monitoring machine*, which is imperfect but
#  better than nothing.
define authdns::monitoring::global($address, $prefixlen=undef) {
    $hostlabel = $title # just for semantic clarity below

    @monitoring::host { $hostlabel: ip_address => $address }

    @monitoring::service { $hostlabel:
        host          => $hostlabel,
        description   => 'Auth DNS',
        check_command => 'check_dns!www.wikipedia.org',
        critical      => true,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/DNS',
    }
}
