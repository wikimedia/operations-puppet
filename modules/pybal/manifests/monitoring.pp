# === Class pybal::monitoring
# Collect data from pybal

class pybal::monitoring(
    String $config_host,
    Enum['etcd', 'http'] $config_source,
    Stdlib::Port::User $etcd_port,
    Hash[String, Wmflib::Service] $services,
) {
    require ::pybal::configuration
    ensure_packages([
        'libmonitoring-plugin-perl',
        'libwww-perl',
        'python-prometheus-client',
        'python-requests',
    ])

    nrpe::plugin { 'check_pybal':
        source => 'puppet:///modules/pybal/check_pybal',
    }

    nrpe::monitor_service { 'pybal_backends':
        description  => 'PyBal backends health check',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_pybal --url http://localhost:9090/alerts',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/PyBal',
    }

    nrpe::plugin { 'check_pybal_ipvs_diff':
        source => 'puppet:///modules/pybal/check_pybal_ipvs_diff.py',
    }

    nrpe::monitor_service { 'pybal_ipvs_diff':
        description    => 'PyBal IPVS diff check',
        nrpe_command   => "/usr/local/lib/nagios/plugins/check_pybal_ipvs_diff --req-timeout=10.0 --prometheus-url http://${::ipaddress}:9100/metrics",
        check_interval => 5,
        timeout        => 60,
        notes_url      => 'https://wikitech.wikimedia.org/wiki/PyBal',
    }

    if $config_source == 'etcd' {
        # Get the configuration of all services for this LVS host
        # then sum all values.
        $n_etcd_connections = map($services) |$name,$service| {
            size($service['ip'][$::site])
        }.reduce() |$memo,$value| { $memo + $value }

        nrpe::monitor_service { 'pybal_etcd_connections':
            description    => 'PyBal connections to etcd',
            nrpe_command   => "/usr/lib/nagios/plugins/check_established_connections ${config_host} ${etcd_port} ${n_etcd_connections}",
            check_interval => 5,
            timeout        => 60,
            notes_url      => 'https://wikitech.wikimedia.org/wiki/PyBal',
        }
    }


    $prometheus_labels = "{instance=\"${::hostname}:9090\"}"
    monitoring::check_prometheus { 'pybal_bgp_sessions':
        description     => 'PyBal BGP sessions are established',
        dashboard_links => ["https://grafana.wikimedia.org/d/000000488/pybal-bgp?var-datasource=${::site} prometheus/ops"],
        query           => "scalar(pybal_bgp_session_established${prometheus_labels} and ignoring (local_asn, peer) pybal_bgp_enabled${prometheus_labels} == 1)",
        method          => 'le',
        warning         => 0,
        critical        => 0,
        nan_ok          => true,
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        notes_link      => 'https://wikitech.wikimedia.org/wiki/PyBal',
    }
}
