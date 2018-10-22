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
    String $purge_host_regex=hiera('profile::trafficserver::backend::purge_host_regex', ''),
    Array[Stdlib::Compat::Ip_address] $purge_multicasts=hiera('profile::trafficserver::backend::purge_multicasts', ['239.128.0.112', '239.128.0.113', '239.128.0.114', '239.128.0.115']),
    Array[String] $purge_endpoints=hiera('profile::trafficserver::backend::purge_endpoints', ['127.0.0.1:3129']),
){
    # Build list of remap rules with default Lua scripts passed as parameters
    $remap_rules_lua = $mapping_rules.map |TrafficServer::Mapping_rule $rule| {
        merge($rule, {
            params => $default_lua_scripts.map |String $lua_script| {
                "@plugin=/usr/lib/trafficserver/modules/tslua.so @pparam=/etc/trafficserver/lua/${lua_script}.lua @pparam=${::hostname}"
            }
        })
    }

    class { '::trafficserver':
        port                      => $port,
        outbound_tls_cipher_suite => $outbound_tls_cipher_suite,
        storage                   => $storage,
        mapping_rules             => $remap_rules_lua,
        caching_rules             => $caching_rules,
    }

    # Install default Lua scripts
    $default_lua_scripts.each |String $lua_script| {
        trafficserver::lua_script { $lua_script:
            source    => "puppet:///modules/profile/trafficserver/${lua_script}.lua",
            unit_test => "puppet:///modules/profile/trafficserver/${lua_script}_test.lua",
        }
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
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -a /usr/bin/traffic_server',
        require      => Class['::trafficserver'],
    }

    nrpe::monitor_service { 'trafficserver_exporter':
        description  => 'Ensure trafficserver_exporter is running',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -a "/usr/bin/python3 /usr/bin/trafficserver_exporter"',
        require      => Prometheus::Trafficserver_exporter['trafficserver_exporter'],
    }

    monitoring::service { 'traffic_manager_check_http':
        description   => 'Ensure traffic_manager binds on $port and responds to HTTP requests',
        check_command => "check_http_hostheader_port_url!localhost!${port}!/_stats",
    }
}
