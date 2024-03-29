define redis::monitoring::nrpe_instance($replica_warning=60, $replica_critical=600){
    require redis::monitoring::nrpe
    $port = $title
    $cmd = '/usr/local/lib/nagios/plugins/nrpe_check_redis'
    nrpe::monitor_service { "redis_status_on_port_${port}":
        ensure         => present,
        description    => "Check health of redis instance on ${port}",
        nrpe_command   => "${cmd} ${port} ${replica_warning} ${replica_critical}",
        sudo_user      => 'root',
        contact_group  => 'admins',
        retry_interval => 2,
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Redis',
    }
}
