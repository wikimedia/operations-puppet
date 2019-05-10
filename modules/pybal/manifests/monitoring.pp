# === Class pybal::monitoring
# Collect data from pybal

class pybal::monitoring(
    String $config_host,
    Enum['etcd', 'http'] $config_source,
    Wmflib::UserIpPort $etcd_port,
    $lvs_services,
    $lvs_class_hosts) {
    require ::pybal::configuration
    require_package([
        'libmonitoring-plugin-perl',
        'libwww-perl',
        'python-prometheus-client',
        'python-requests',
    ])

    file { '/usr/local/lib/nagios/plugins/check_pybal':
        ensure => present,
        source => 'puppet:///modules/pybal/check_pybal',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    nrpe::monitor_service { 'pybal_backends':
        description  => 'PyBal backends health check',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_pybal --url http://localhost:9090/alerts',
        require      => File['/usr/local/lib/nagios/plugins/check_pybal'],
        notes_url    => 'https://wikitech.wikimedia.org/wiki/PyBal',
    }

    file { '/usr/local/lib/nagios/plugins/check_pybal_ipvs_diff':
        ensure => present,
        source => 'puppet:///modules/pybal/check_pybal_ipvs_diff.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    nrpe::monitor_service { 'pybal_ipvs_diff':
        description    => 'PyBal IPVS diff check',
        nrpe_command   => "/usr/local/lib/nagios/plugins/check_pybal_ipvs_diff --req-timeout=10.0 --prometheus-url http://${::ipaddress}:9100/metrics",
        check_interval => 5,
        timeout        => 60,
        require        => File['/usr/local/lib/nagios/plugins/check_pybal_ipvs_diff'],
        notes_url      => 'https://wikitech.wikimedia.org/wiki/PyBal',
    }

    if $config_source == 'etcd' {
        # Get the configuration of all services for this LVS host
        $services = filter($lvs_services) |$name,$service| {
            $::site in $service['sites'] and $::hostname in $lvs_class_hosts[$service['class']]
        }
        # Every given service might be configured twice (IPv4 and IPv6)
        $ip_class_services = map($services) |$name,$service| {
            type($service['ip'][$::site]) ? {
                Type[String] => 1,
                default      => size($service['ip'][$::site]),
            }
        }
        # Sum all values
        $n_etcd_connections = reduce($ip_class_services) |$memo,$value| { $memo + $value }

        nrpe::monitor_service { 'pybal_etcd_connections':
            description    => 'PyBal connections to etcd',
            nrpe_command   => "/usr/lib/nagios/plugins/check_established_connections ${config_host} ${etcd_port} ${n_etcd_connections}",
            check_interval => 5,
            timeout        => 60,
            require        => File['/usr/lib/nagios/plugins/check_established_connections'],
            notes_url      => 'https://wikitech.wikimedia.org/wiki/PyBal',
        }
    }


    $prometheus_labels = "{instance=\"${::hostname}:9090\"}"
    monitoring::check_prometheus { 'pybal_bgp_sessions':
        description     => 'PyBal BGP sessions are established',
        dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/pybal-bgp?var-datasource=${::site} prometheus/ops"],
        query           => "scalar(pybal_bgp_session_established${prometheus_labels} and ignoring (local_asn, peer) pybal_bgp_enabled${prometheus_labels} == 1)",
        method          => 'le',
        warning         => 0,
        critical        => 0,
        nan_ok          => true,
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        notes_link      => 'https://wikitech.wikimedia.org/wiki/PyBal',
    }
}
