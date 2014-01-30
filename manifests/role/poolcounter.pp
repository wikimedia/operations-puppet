class role::poolcounter (
    $poolcounter_ip   = '0.0.0.0',
    $poolcounter_port = '7531',
){
    include ::poolcounter
    include nrpe
    system::role { 'role::poolcounter':
        description => 'PoolCounter server',
    }

    # Process running
    nrpe::monitor_service { 'poolcounterd':
        description   => 'poolcounter',
        check_command => "/usr/lib/nagios/plugins/check_nrpe -H ${poolcounter_ip} -c check_poolcounterd",
    }

    # TCP port 7531 reacheable
    nrpe::monitor_service { 'poolcounterd_port_7531':
        description   => 'Poolcounter connection',
        check_command => "/usr/lib/nagios/plugins/check_tcp -H ${poolcounter_ip} -p ${poolcounter_port}",
    }

}

