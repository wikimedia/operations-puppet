define profile::trafficserver::monitoring(
    Trafficserver::Paths $paths,
    Stdlib::Port $port,
    Stdlib::Port::User $prometheus_exporter_port,
    Optional[Trafficserver::Inbound_TLS_settings] $inbound_tls = undef,
    Boolean $default_instance = false,
    Boolean $acme_chief = false,
    Boolean $disable_config_check = false,
    String $instance_name = 'backend',
    String $user = 'trafficserver',
){
    # This profile depends on some resources created by profile::monitoring
    include profile::monitoring

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
        ensure    => bool2str(!$disable_config_check, 'present', 'absent'),
        sudo_user => $user,
        checkname => 'check_trafficserver_config_status',
        args      => $check_trafficserver_config_status_args,
        require   => Trafficserver::Instance[$instance_name],
    }

    if $inbound_tls {
        $inbound_tls['certificates'].each |Trafficserver::TLS_certificate $certificate| {
            if $certificate['common_name'] and $certificate['sni'] and $certificate['warning_threshold'] and $certificate['critical_threshold'] {
                if $inbound_tls['do_ocsp'] == 1 {
                    $check_ocsp = 'check_ssl_ats_ocsp'
                } else {
                    $check_ocsp = 'check_ssl_ats'
                }
                if $certificate['default'] {
                    $check = "${check_ocsp}_default"
                } else {
                    $check = $check_ocsp
                }
                $check_sni_str = join($certificate['sni'], ',')
                ['ECDSA', 'RSA'].each |String $algorithm| {
                    monitoring::service { "trafficserver_${instance_name}_https_${certificate['common_name']}_${algorithm}":
                        description   => "ats-${instance_name} HTTPS ${certificate['common_name']} ${algorithm}",
                        check_command => "${check}!${certificate['warning_threshold']}!${certificate['critical_threshold']}!${certificate['common_name']}!${check_sni_str}!${port}!${algorithm}",
                        notes_url     => 'https://wikitech.wikimedia.org/wiki/HTTPS',
                    }
                }
            }
        }
        if $inbound_tls['do_ocsp'] == 1 {
            $check_args = '-c 259500 -w 173100 -d /var/cache/ocsp -g "*.ocsp"'
            $check_args_acme_chief = '-c 518400 -w 432000 -d /etc/acmecerts -g "*/live/*.ocsp"'
            nrpe::monitor_service { "trafficserver_${instance_name}_ocsp_freshness":
                description  => 'Freshness of OCSP Stapling files (ATS-TLS)',
                nrpe_command => "/usr/local/lib/nagios/plugins/check_fresh_files_in_dir ${check_args}",
                notes_url    => 'https://wikitech.wikimedia.org/wiki/HTTPS/Unified_Certificates',
            }
            nrpe::monitor_service { "trafficserver_${instance_name}_ocsp_freshness_acme_chief":
                ensure       => bool2str($acme_chief, 'present', 'absent'),
                description  => 'Freshness of OCSP Stapling files (ATS-TLS acme-chief)',
                nrpe_command => "/usr/local/lib/nagios/plugins/check_fresh_files_in_dir ${check_args_acme_chief}",
                notes_url    => 'https://wikitech.wikimedia.org/wiki/HTTPS/Unified_Certificates',
            }
        }
    }

    $prometheus_labels = "instance=~\"${::hostname}:.*\",layer=\"${instance_name}\""

    # In normal conditions, restart count is 1. Alert if it is >= 2.
    monitoring::check_prometheus { "trafficserver_${instance_name}_restart_count":
        description     => "traffic_server ${instance_name} process restarted",
        dashboard_links => ["https://grafana.wikimedia.org/d/6uhkG6OZk/ats-instance-drilldown?orgId=1&var-site=${::site} prometheus/ops&var-instance=${::hostname}&var-layer=${instance_name}"],
        query           => "scalar(trafficserver_restart_count{${prometheus_labels}})",
        method          => 'ge',
        warning         => 2,
        critical        => 2,
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Apache_Traffic_Server',
    }
}
