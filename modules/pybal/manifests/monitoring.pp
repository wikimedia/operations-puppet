# === Class pybal::monitoring
# Collect data from pybal

class pybal::monitoring {

    require_package([
        'libnagios-plugin-perl',
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
        description  => 'PyBal IPVS diff check',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_pybal_ipvs_diff',
        require      => File['/usr/local/lib/nagios/plugins/check_pybal_ipvs_diff'],
    }
}
