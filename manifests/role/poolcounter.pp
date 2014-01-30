class role::poolcounter{
    include ::poolcounter
    include nrpe
    system::role { 'role::poolcounter':
        description => 'PoolCounter server',
    }

    # Process running
    nrpe::monitor_service { 'poolcounterd':
        description   => 'poolcounter',
        check_command => 'check_poolcounterd',
    }

    # TCP port 7531 reacheable
    monitor_service { 'poolcounterd_port_7531':
        description   => 'Poolcounter connection',
        check_command => 'check_tcp!7531',
    }

}

