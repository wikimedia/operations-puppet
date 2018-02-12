# === Class pybal::monitoring
# Collect data from pybal

class pybal::monitoring($config_host="config-master.${site}.wmnet") {

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

    nrpe::monitor_service { 'pybal_etcd_connections':
        description    => 'PyBal connections to etcd',
        nrpe_command   => "/usr/lib/nagios/plugins/check_established_connections ${config_host} 2379 1",
        check_interval => 5,
        timeout        => 60,
        require        => File['/usr/lib/nagios/plugins/check_established_connections'],
    }
}
