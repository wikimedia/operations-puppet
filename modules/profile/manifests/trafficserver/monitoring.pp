define profile::trafficserver::monitoring(
    Trafficserver::Paths $paths,
    Wmflib::UserIpPort $port,
    Wmflib::UserIpPort $prometheus_exporter_port,
    Boolean $inbound_tls = false,
    Boolean $default_instance = false,
    String $instance_name = 'backend',
    String $user = 'trafficserver',
){
    if $inbound_tls {
        $endpoint = "https://127.0.0.1:${port}/_stats"
        $traffic_manager_http_check = 'check_https_hostheader_port_url'
    } else {
        $endpoint = "http://127.0.0.1:${port}/_stats"
        $traffic_manager_http_check = 'check_http_hostheader_port_url'
    }

    if $default_instance {
        $traffic_manager_nrpe_command = '/usr/lib/nagios/plugins/check_procs -c 1:1 -a "/usr/bin/traffic_manager --nosyslog"'
        $traffic_server_nrpe_command = "/usr/lib/nagios/plugins/check_procs -c 1:1 -a '/usr/bin/traffic_server -M --httpport ${port}'"
        $check_trafficserver_config_status_args = $paths['records']
    } else {
        $traffic_manager_nrpe_command = "/usr/lib/nagios/plugins/check_procs -c 1:1 -a '/usr/bin/traffic_manager --run-root=/srv/trafficserver/${instance_name} --nosyslog'"
        $traffic_server_nrpe_command = "/usr/lib/nagios/plugins/check_procs -c 1:1 -a '/usr/bin/traffic_server --run-root=/srv/trafficserver/${instance_name} -M --httpport ${port}'"
        $check_trafficserver_config_status_args = "${paths['records']} ${paths['prefix']}"
    }

    prometheus::trafficserver_exporter { "trafficserver_exporter_${instance_name}":
        instance_name          => $instance_name,
        endpoint               => $endpoint,
        listen_port            => $prometheus_exporter_port,
        verify_ssl_certificate => false,
        require                => Trafficserver::Instance[$instance_name],
    }

    nrpe::monitor_service { "traffic_manager_${instance_name}":
        description  => "Ensure traffic_manager is running for instance ${instance_name}",
        nrpe_command => $traffic_manager_nrpe_command,
        require      => Trafficserver::Instance[$instance_name],
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Apache_Traffic_Server',
    }

    nrpe::monitor_service { "traffic_server_${instance_name}":
        description  => "Ensure traffic_server is running for instance ${instance_name}",
        nrpe_command => $traffic_server_nrpe_command,
        require      => Trafficserver::Instance[$instance_name],
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Apache_Traffic_Server',
    }

    nrpe::monitor_service { "trafficserver_exporter_${instance_name}":
        description  => "Ensure trafficserver_exporter is running for instance ${instance_name}",
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -a '/usr/bin/python3 /usr/bin/prometheus-trafficserver-exporter --no-procstats --no-ssl-verification --endpoint ${endpoint} --port ${prometheus_exporter_port}'",
        require      => Prometheus::Trafficserver_exporter["trafficserver_exporter_${instance_name}"],
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Apache_Traffic_Server',
    }

    monitoring::service { "traffic_manager_${instance_name}_check_http":
        description   => "Ensure traffic_manager binds on ${port} and responds to HTTP requests",
        check_command => "${traffic_manager_http_check}!localhost!${port}!/_stats",
        require       => Prometheus::Trafficserver_exporter["trafficserver_exporter_${instance_name}"],
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Apache_Traffic_Server',
    }

    profile::trafficserver::nrpe_monitor_script { "check_trafficserver_${instance_name}_config_status":
        sudo_user => $user,
        checkname => 'check_trafficserver_config_status',
        args      => $check_trafficserver_config_status_args,
        require   => Trafficserver::Instance[$instance_name],
    }

    # XXX: Avoid `traffic_server -C verify_config` for now
    #profile::trafficserver::nrpe_monitor_script { 'check_trafficserver_verify_config':
    #    sudo_user => $user,
    #}
}
