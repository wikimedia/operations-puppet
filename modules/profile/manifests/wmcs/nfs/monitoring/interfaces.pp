#
# Generic monitoring for all cloudstore NFS servers
#
# == Parameters
#
# [*monitor_iface*]
#   Name of interface to monitor for network saturation.
#   This should be the interface holding the IP address
#   that serves NFS

class profile::wmcs::nfs::monitoring::interfaces (
    String  $monitor_iface        = lookup('profile::wmcs::nfs::monitoring::interfaces::monitor_iface'),
    String  $contact_groups       = lookup('profile::wmcs::nfs::monitoring::interfaces::contact_groups'),
    Integer $int_throughput_warn  = lookup('profile::wmcs::nfs::monitoring::interfaces::int_throughput_warn'),
    Integer $int_throughput_crit  = lookup('profile::wmcs::nfs::monitoring::interfaces::int_throughput_crit'),
    Float   $load_warn_ratio      = lookup('profile::wmcs::nfs::monitoring::interfaces::load_warn_ratio'),
    Float   $load_crit_ratio      = lookup('profile::wmcs::nfs::monitoring::interfaces::load_crit_ratio'),
    Stdlib::HTTPUrl $graphite_url = lookup('graphite_url'),
) {

    $interval = '10min' # see T188624

    Monitoring::Graphite_threshold {
        graphite_url => $graphite_url,
    }

    monitoring::graphite_threshold { 'network_out_saturated':
        description     => 'Outgoing network saturation',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/labs-monitoring'],
        metric          => "servers.${::hostname}.network.${monitor_iface}.tx_byte",
        from            => $interval,
        warning         => $int_throughput_warn,
        critical        => $int_throughput_crit,
        percentage      => '10',        # smooth over peaks
        contact_group   => $contact_groups,
    }

    monitoring::graphite_threshold { 'network_in_saturated':
        description     => 'Incoming network saturation',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/labs-monitoring'],
        metric          => "servers.${::hostname}.network.${monitor_iface}.rx_byte",
        from            => $interval,
        warning         => $int_throughput_warn,
        critical        => $int_throughput_crit,
        percentage      => '10',        # smooth over peaks
        contact_group   => $contact_groups,
    }

    monitoring::graphite_threshold { 'high_iowait_stalling':
        description     => 'Persistent high iowait',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/labs-monitoring'],
        metric          => "servers.${::hostname}.cpu.total.iowait",
        from            => '10min',
        warning         => '40', # Based off looking at history of metric
        critical        => '60',
        percentage      => '50', # Ignore small spikes
        contact_group   => $contact_groups,
    }

    # Monitor for high load consistently, is a 'catchall'
    monitoring::graphite_threshold { 'high_load':
        description     => 'High load average',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/labs-monitoring'],
        metric          => "servers.${::hostname}.loadavg.01",
        from            => '10min',
        warning         => $::processorcount * $load_warn_ratio,
        critical        => $::processorcount * $load_crit_ratio,
        percentage      => '85', # Don't freak out on spikes
        contact_group   => $contact_groups,
    }
}
