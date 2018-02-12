# === Class pybal::monitoring
# Collect data from pybal

class pybal::monitoring($config_host, $lvs_services, $lvs_class_hosts) {

    require_package([
        'libmonitoring-plugin-perl',
        'python-prometheus-client',
        'python-requests',
    ])

    diamond::collector { 'PyBalState':
        source => 'puppet:///modules/pybal/pybal_state.py',
    }

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
    }

    # Get the configuration of all services for this LVS host
    $services = filter($lvs_services) |$name,$service| { $::site in $service['sites'] and $::hostname in $lvs_class_hosts[$service['class']] }

    # Every given service might be configured twice (IPv4 and IPv6)
    $ip_class_services = map($services) |$name,$service| {
        type($service['ip'][$::site]) ? {
            Type[Array]  => 2,
            Type[String] => 1,
            default      => fail('Unexpected data in service configuration'),
        }
    }

    # Sum all values
    $n_etcd_connections = reduce($ip_class_services) |$memo,$value| { $memo + $value }

    nrpe::monitor_service { 'pybal_etcd_connections':
        description    => 'PyBal connections to etcd',
        nrpe_command   => "/usr/lib/nagios/plugins/check_established_connections ${config_host} 2379 ${n_etcd_connections}",
        check_interval => 5,
        timeout        => 60,
        require        => File['/usr/lib/nagios/plugins/check_established_connections'],
    }
}
