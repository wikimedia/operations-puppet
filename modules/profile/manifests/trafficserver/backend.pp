# === class profile::trafficserver::backend
#
# Sets up a Traffic Server backend instance with HTCP-based HTTP purging and
# Nagios checks.
#
class profile::trafficserver::backend (
    Wmflib::IpPort $port=hiera('profile::trafficserver::backend::port', 3129),
    String $outbound_tls_cipher_suite=hiera('profile::trafficserver::backend::outbound_tls_cipher_suite', ''),
    Array[TrafficServer::Mapping_rule] $mapping_rules=hiera('profile::trafficserver::backend::mapping_rules', []),
    Array[TrafficServer::Caching_rule] $caching_rules=hiera('profile::trafficserver::backend::caching_rules', []),
    Array[String] $default_lua_scripts=hiera('profile::trafficserver::backend::default_lua_scripts', []),
    Array[TrafficServer::Storage_element] $storage=hiera('profile::trafficserver::backend::storage_elements', []),
    Array[TrafficServer::Log_format] $log_formats=hiera('profile::trafficserver::backend::log_formats', []),
    Array[TrafficServer::Log_filter] $log_filters=hiera('profile::trafficserver::backend::log_filters', []),
    Array[TrafficServer::Log] $logs=hiera('profile::trafficserver::backend::logs', []),
    String $purge_host_regex=hiera('profile::trafficserver::backend::purge_host_regex', ''),
    Array[Stdlib::Compat::Ip_address] $purge_multicasts=hiera('profile::trafficserver::backend::purge_multicasts', ['239.128.0.112', '239.128.0.113', '239.128.0.114', '239.128.0.115']),
    Array[String] $purge_endpoints=hiera('profile::trafficserver::backend::purge_endpoints', ['127.0.0.1:3129']),
){
    # Build list of remap rules with Lua scripts passed as parameters.
    # Pass the default Lua scripts to all remap rules, adding rule-specific
    # scripts if they have been specified.
    $remap_rules_lua = $mapping_rules.map |TrafficServer::Mapping_rule $rule| {
        if (has_key($rule, 'params')) {
            $rule_specific_params = $rule["params"]
        } else {
            $rule_specific_params = []
        }
        merge($rule, {
            params => $default_lua_scripts.map |String $lua_script| {
                "@plugin=/usr/lib/trafficserver/modules/tslua.so @pparam=/etc/trafficserver/lua/${lua_script}.lua @pparam=${::hostname}"
            } + $rule_specific_params
        })
    }

    class { '::trafficserver':
        port                      => $port,
        outbound_tls_cipher_suite => $outbound_tls_cipher_suite,
        storage                   => $storage,
        mapping_rules             => $remap_rules_lua,
        caching_rules             => $caching_rules,
        log_formats               => $log_formats,
        log_filters               => $log_filters,
        logs                      => $logs,
    }

    # Install default Lua scripts
    $default_lua_scripts.each |String $lua_script| {
        trafficserver::lua_script { $lua_script:
            source    => "puppet:///modules/profile/trafficserver/${lua_script}.lua",
            unit_test => "puppet:///modules/profile/trafficserver/${lua_script}_test.lua",
        }
    }

    trafficserver::lua_script { 'x-mediawiki-original':
        source    => 'puppet:///modules/profile/trafficserver/x-mediawiki-original.lua',
        unit_test => 'puppet:///modules/profile/trafficserver/x-mediawiki-original_test.lua',
    }

    prometheus::trafficserver_exporter { 'trafficserver_exporter':
        endpoint => "http://127.0.0.1:${port}/_stats",
    }

    # Purging
    class { '::varnish::htcppurger':
        host_regex => $purge_host_regex,
        mc_addrs   => $purge_multicasts,
        varnishes  => $purge_endpoints,
    }

    # Nagios checks
    nrpe::monitor_service { 'traffic_manager':
        description  => 'Ensure traffic_manager is running',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -a "/usr/bin/traffic_manager --nosyslog"',
        require      => Class['::trafficserver'],
    }

    nrpe::monitor_service { 'traffic_server':
        description  => 'Ensure traffic_server is running',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -a '/usr/bin/traffic_server -M --httpport ${port}'",
        require      => Class['::trafficserver'],
    }

    nrpe::monitor_service { 'trafficserver_exporter':
        description  => 'Ensure trafficserver_exporter is running',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -a "/usr/bin/python3 /usr/bin/prometheus-trafficserver-exporter"',
        require      => Prometheus::Trafficserver_exporter['trafficserver_exporter'],
    }

    monitoring::service { 'traffic_manager_check_http':
        description   => 'Ensure traffic_manager binds on $port and responds to HTTP requests',
        check_command => "check_http_hostheader_port_url!localhost!${port}!/_stats",
    }

    profile::trafficserver::nrpe_monitor_script { 'check_trafficserver_config_status':
        sudo_user => $trafficserver::user,
    }

    # XXX: Avoid `traffic_server -C verify_config` for now
    #profile::trafficserver::nrpe_monitor_script { 'check_trafficserver_verify_config':
    #    sudo_user => $trafficserver::user,
    #}

    $logs.each |TrafficServer::Log $log| {
        if $log['mode'] == 'ascii_pipe' {
            fifo_log_demux::instance { $log['filename']:
                user      => $trafficserver::user,
                fifo      => "/var/log/trafficserver/${log['filename']}.pipe",
                socket    => "/var/run/trafficserver/${log['filename']}.sock",
                wanted_by => 'trafficserver.service',
            }

            profile::trafficserver::nrpe_monitor_script { "check_trafficserver_log_fifo_${log['filename']}":
                sudo_user => 'root',
                checkname => 'check_trafficserver_log_fifo',
                args      => "/var/log/trafficserver/${log['filename']}.pipe",
            }
        }
    }

    # Wrapper script to print ATS logs to stdout using fifo-log-tailer
    file { '/usr/local/bin/atslog':
        ensure => present,
        source => 'puppet:///modules/profile/trafficserver/atslog.sh',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }
}
