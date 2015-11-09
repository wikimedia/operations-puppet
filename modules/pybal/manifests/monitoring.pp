# === Class pybal::monitoring
# Collect data from pybal

class pybal::monitoring {

    diamond::collector { 'PyBalState':
        source => 'puppet:///modules/pybal/pybal_state.py'
    }

    file { '/usr/local/lib/nagios/plugins/check_pybal':
        ensure  => present,
        source  => 'puppet:///modules/pybal/check_pybal',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
    }

    nrpe::monitor_service { 'pybal_backends':
        description  => 'PyBal backends health check',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_pybal',
        require      => File['/usr/local/lib/nagios/plugins/check_pybal']
    }

}
