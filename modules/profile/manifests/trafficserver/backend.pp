# === class profile::trafficserver::backend
#
# Sets up a Traffic Server backend instance with HTCP-based HTTP purging and
# Nagios checks.
#
class profile::trafficserver::backend (
    Wmflib::IpPort $port=hiera('profile::trafficserver::backend::port', 3129),
    String $outbound_tls_cipher_suite=hiera('profile::trafficserver::backend::outbound_tls_cipher_suite', ''),
    Boolean $enable_xdebug=hiera('profile::trafficserver::backend::enable_xdebug', false),
    Array[TrafficServer::Mapping_rule] $mapping_rules=hiera('profile::trafficserver::backend::mapping_rules', []),
    Array[TrafficServer::Caching_rule] $caching_rules=hiera('profile::trafficserver::backend::caching_rules', []),
    String $default_lua_script=hiera('profile::trafficserver::backend::default_lua_script', ''),
    Array[TrafficServer::Storage_element] $storage=hiera('profile::trafficserver::backend::storage_elements', []),
    Array[TrafficServer::Log_format] $log_formats=hiera('profile::trafficserver::backend::log_formats', []),
    Array[TrafficServer::Log_filter] $log_filters=hiera('profile::trafficserver::backend::log_filters', []),
    Array[TrafficServer::Log] $logs=hiera('profile::trafficserver::backend::logs', []),
    String $purge_host_regex=hiera('profile::trafficserver::backend::purge_host_regex', ''),
    Array[Stdlib::Compat::Ip_address] $purge_multicasts=hiera('profile::trafficserver::backend::purge_multicasts', ['239.128.0.112', '239.128.0.113', '239.128.0.114', '239.128.0.115']),
    Array[String] $purge_endpoints=hiera('profile::trafficserver::backend::purge_endpoints', ['127.0.0.1:3129']),
){
    # Add hostname as a parameter to the default global Lua plugin
    $global_lua_script = $default_lua_script? {
        ''      => '',
        default => "/etc/trafficserver/lua/${default_lua_script}.lua ${::hostname}",
    }

    class { '::trafficserver':
        port                         => $port,
        outbound_tls_cipher_suite    => $outbound_tls_cipher_suite,
        outbound_tls_cacert_filename => 'Puppet_Internal_CA.pem',
        enable_xdebug                => $enable_xdebug,
        global_lua_script            => $global_lua_script,
        storage                      => $storage,
        mapping_rules                => $mapping_rules,
        caching_rules                => $caching_rules,
        log_formats                  => $log_formats,
        log_filters                  => $log_filters,
        logs                         => $logs,
    }

    # Install default Lua script
    if $default_lua_script != '' {
        trafficserver::lua_script { $default_lua_script:
            source    => "puppet:///modules/profile/trafficserver/${default_lua_script}.lua",
            unit_test => "puppet:///modules/profile/trafficserver/${default_lua_script}_test.lua",
        }
    }

    trafficserver::lua_script { 'x-mediawiki-original':
        source    => 'puppet:///modules/profile/trafficserver/x-mediawiki-original.lua',
        unit_test => 'puppet:///modules/profile/trafficserver/x-mediawiki-original_test.lua',
    }

    trafficserver::lua_script { 'normalize-path':
        source    => 'puppet:///modules/profile/trafficserver/normalize-path.lua',
    }

    trafficserver::lua_script { 'rb-mw-mangling':
        source    => 'puppet:///modules/profile/trafficserver/rb-mw-mangling.lua',
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
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Apache_Traffic_Server',
    }

    nrpe::monitor_service { 'traffic_server':
        description  => 'Ensure traffic_server is running',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -a '/usr/bin/traffic_server -M --httpport ${port}'",
        require      => Class['::trafficserver'],
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Apache_Traffic_Server',
    }

    nrpe::monitor_service { 'trafficserver_exporter':
        description  => 'Ensure trafficserver_exporter is running',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -a "/usr/bin/python3 /usr/bin/prometheus-trafficserver-exporter"',
        require      => Prometheus::Trafficserver_exporter['trafficserver_exporter'],
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Apache_Traffic_Server',
    }

    monitoring::service { 'traffic_manager_check_http':
        description   => 'Ensure traffic_manager binds on $port and responds to HTTP requests',
        check_command => "check_http_hostheader_port_url!localhost!${port}!/_stats",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Apache_Traffic_Server',
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
