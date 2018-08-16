class profile::trafficserver::backend (
    Wmflib::IpPort $port=hiera('profile::trafficserver::backend::port', 3129),
    String $outbound_tls_cipher_suite=hiera('profile::trafficserver::backend::outbound_tls_cipher_suite', ''),
    Array[TrafficServer::Mapping_rule] $mapping_rules=hiera('profile::trafficserver::backend::mapping_rules', []),
    Array[String] $default_lua_scripts=hiera('profile::trafficserver::backend::default_lua_scripts', []),
    Array[TrafficServer::Storage_element] $storage=hiera('profile::trafficserver::backend::storage_elements', []),
){
    # Build list of remap rules with default Lua scripts passed as parameters
    $remap_rules_lua = $mapping_rules.map |TrafficServer::Mapping_rule $rule| {
        merge($rule, {
            params => $default_lua_scripts.map |String $lua_script| {
                "@plugin=/usr/lib/trafficserver/modules/tslua.so @pparam=/etc/trafficserver/lua/${lua_script}.lua"
            }
        })
    }

    class { '::trafficserver':
        port                      => $port,
        outbound_tls_cipher_suite => $outbound_tls_cipher_suite,
        storage                   => $storage,
        mapping_rules             => $remap_rules_lua,
    }

    # Install default Lua scripts
    $default_lua_scripts.each |String $lua_script| {
        trafficserver::lua_script { $lua_script:
            source    => "puppet:///modules/profile/trafficserver/${lua_script}.lua",
            unit_test => "puppet:///modules/profile/trafficserver/${lua_script}_test.lua",
        }
    }
}
