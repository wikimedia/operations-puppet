# SPDX-License-Identifier: Apache-2.0
define profile::trafficserver::monitoring(
    Trafficserver::Paths $paths,
    Stdlib::Port $port,
    Stdlib::Port::User $prometheus_exporter_port,
    Optional[Trafficserver::Network_settings] $network_settings = undef,
    Boolean $default_instance = false,
    Boolean $acme_chief = false,
    Boolean $disable_config_check = false,
    String $instance_name = 'backend',
    String $user = 'trafficserver',
){
    # This profile depends on some resources created by profile::monitoring
    include profile::monitoring

    $endpoint = "http://127.0.0.1:${port}/_stats"
    $traffic_manager_http_check = 'check_http_hostheader_port_url'

    if $default_instance {
        $traffic_manager_nrpe_command = '/usr/lib/nagios/plugins/check_procs -c 1:1 -a "/usr/bin/traffic_manager --nosyslog"'
        $traffic_server_nrpe_command = "/usr/lib/nagios/plugins/check_procs -c 1:1 -a '/usr/bin/traffic_server -M --httpport ${port}'"
        $check_trafficserver_config_status_args = $paths['records']
    } else {
        $traffic_manager_nrpe_command = "/usr/lib/nagios/plugins/check_procs -c 1:1 -a '/usr/bin/traffic_manager --run-root=${paths['prefix']} --nosyslog'"
        $traffic_server_nrpe_command = "/usr/lib/nagios/plugins/check_procs -c 1:1 -a '${paths['bindir']}/traffic_server -M --run-root=${paths['prefix']}/runroot.yaml --httpport ${port}'"
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
        description    => "Ensure traffic_manager is running for instance ${instance_name}",
        nrpe_command   => $traffic_manager_nrpe_command,
        require        => Trafficserver::Instance[$instance_name],
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Apache_Traffic_Server',
        migration_task => 'T385587',
    }

    nrpe::monitor_service { "traffic_server_${instance_name}":
        description    => "Ensure traffic_server is running for instance ${instance_name}",
        nrpe_command   => $traffic_server_nrpe_command,
        require        => Trafficserver::Instance[$instance_name],
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Apache_Traffic_Server',
        migration_task => 'T385587',
    }

    nrpe::monitor_service { "trafficserver_exporter_${instance_name}":
        description  => "Ensure trafficserver_exporter is running for instance ${instance_name}",
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -a '/usr/bin/python3 /usr/bin/prometheus-trafficserver-exporter --no-procstats --no-ssl-verification --endpoint ${endpoint} --port ${prometheus_exporter_port}'",
        require      => Prometheus::Trafficserver_exporter["trafficserver_exporter_${instance_name}"],
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Apache_Traffic_Server',
    }

    if $network_settings['max_connections_in'] and $network_settings['max_requests_in'] {
        prometheus::node_trafficserver_config { "trafficserver_${instance_name}_config":
            config_max_conns => $network_settings['max_connections_in'],
            config_max_reqs  => $network_settings['max_requests_in'],
            outfile          => "/var/lib/prometheus/node.d/trafficserver_config_${instance_name}.prom",
        }
    }

    monitoring::service { "traffic_manager_${instance_name}_check_http":
        description    => "Ensure traffic_manager binds on ${port} and responds to HTTP requests",
        check_command  => "${traffic_manager_http_check}!localhost!${port}!/_stats",
        require        => Prometheus::Trafficserver_exporter["trafficserver_exporter_${instance_name}"],
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Apache_Traffic_Server',
        migration_task => 'T385587',
    }

    profile::trafficserver::nrpe_monitor_script { "check_trafficserver_${instance_name}_config_status":
        ensure    => bool2str(!$disable_config_check, 'present', 'absent'),
        sudo_user => $user,
        checkname => 'check_trafficserver_config_status',
        args      => $check_trafficserver_config_status_args,
        require   => Trafficserver::Instance[$instance_name],
    }

}
