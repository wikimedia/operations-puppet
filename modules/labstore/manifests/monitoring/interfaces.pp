#
# Generic monitoring for all labstore NFS servers
#
# == Parameters
#
# [*monitor_iface*]
#   Name of interface to monitor for network saturation.
#   This should be the interface holding the IP address
#   that serves NFS

class labstore::monitoring::interfaces(
    $monitor_iface = 'eth0',
    $contact_groups='wmcs-team,admins',
    $int_throughput_warn = 93750000,  # 750Mbps
    $int_throughput_crit = 106250000, # 850Mbps
    $load_warn = $::processorcount * 0.75,
    $load_crit = $::processorcount * 1.25,
) {

    $interval = '10min' # see T188624

    monitoring::graphite_threshold { 'network_out_saturated':
        description     => 'Outgoing network saturation',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/labs-monitoring'],
        metric          => "servers.${::hostname}.network.${monitor_iface}.tx_byte",
        from            => $interval,
        warning         => $int_throughput_warn,
        critical        => $int_throughput_crit,
        percentage      => 10,        # smooth over peaks
        contact_group   => $contact_groups,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Portal:Data_Services/Admin/Labstore',
    }

    monitoring::graphite_threshold { 'network_in_saturated':
        description     => 'Incoming network saturation',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/labs-monitoring'],
        metric          => "servers.${::hostname}.network.${monitor_iface}.rx_byte",
        from            => $interval,
        warning         => $int_throughput_warn,
        critical        => $int_throughput_crit,
        percentage      => 10,        # smooth over peaks
        contact_group   => $contact_groups,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Portal:Data_Services/Admin/Labstore',
    }

    monitoring::graphite_threshold { 'high_iowait_stalling':
        description     => 'Persistent high iowait',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/labs-monitoring'],
        metric          => "servers.${::hostname}.cpu.total.iowait",
        from            => '10min',
        warning         => 40, # Based off looking at history of metric
        critical        => 60,
        percentage      => 50, # Ignore small spikes
        contact_group   => $contact_groups,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Portal:Data_Services/Admin/Labstore',
    }

    # Monitor for high load consistently, is a 'catchall'
    monitoring::graphite_threshold { 'high_load':
        description     => 'High load average',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/labs-monitoring'],
        metric          => "servers.${::hostname}.loadavg.01",
        from            => '10min',
        warning         => $load_warn,
        critical        => $load_crit,
        percentage      => 85, # Don't freak out on spikes
        contact_group   => $contact_groups,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Portal:Data_Services/Admin/Labstore',
    }
}
