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
    String $monitor_iface = 'eth0',
    String $contact_groups='wmcs-team,admins',
    Integer $int_throughput_warn = 937500000,  # 7.5Gbps
    Integer $int_throughput_crit = 1062500000, # 8.5Gbps
){

    # In minutes, how long icinga will wait before considering HARD state, see also T188624
    $retries = 10

    monitoring::check_prometheus { 'network_out_saturated':
        description     => 'Outgoing network saturation',
        dashboard_links => ['https://grafana.wikimedia.org/d/000000568/labstore1004-1005'],
        query           => "sum(irate(node_network_transmit_bytes_total{instance=\"${::hostname}:9100\",device=\"${monitor_iface}\"}[5m]))",
        warning         => $int_throughput_warn,
        critical        => $int_throughput_crit,
        retries         => $retries,
        method          => 'ge',
        contact_group   => $contact_groups,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Portal:Data_Services/Admin/Labstore',
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
    }

    monitoring::check_prometheus { 'network_in_saturated':
        description     => 'Incoming network saturation',
        dashboard_links => ['https://grafana.wikimedia.org/d/000000568/labstore1004-1005'],
        query           => "sum(irate(node_network_receive_bytes_total{instance=\"${::hostname}:9100\",device=\"${monitor_iface}\"}[5m]))",
        warning         => $int_throughput_warn,
        critical        => $int_throughput_crit,
        retries         => $retries,
        method          => 'ge',
        contact_group   => $contact_groups,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Portal:Data_Services/Admin/Labstore',
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
    }

    monitoring::check_prometheus { 'high_iowait_stalling':
        description     => 'Persistent high iowait',
        dashboard_links => ['https://grafana.wikimedia.org/d/000000568/labstore1004-1005'],
        # iowait % across all CPUs
        query           => "100 * sum(irate(node_cpu_seconds_total{instance=\"${::hostname}:9100\",mode=\"iowait\"}[5m])) / scalar(count(node_cpu_seconds_total{mode=\"idle\",instance=\"${::hostname}:9100\"}))",
        warning         => 5,
        critical        => 10,
        retries         => $retries,
        method          => 'ge',
        contact_group   => $contact_groups,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Portal:Data_Services/Admin/Labstore',
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
    }
}
