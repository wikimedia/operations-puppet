# SPDX-License-Identifier: Apache-2.0
define trafficserver::lua_infra(
    String $service_name='trafficserver',
    Stdlib::Absolutepath $config_prefix='/etc/trafficserver',
) {
    ensure_packages('lua-busted')

    file { "${config_prefix}/lua/":
        ensure => directory,
        mode   => '0755',
        owner  => $trafficserver::user,
    }

    file { "${config_prefix}/lua/mock.helper.lua":
        ensure => present,
        owner  => $trafficserver::user,
        source => 'puppet:///modules/profile/trafficserver/mock.helper.lua',
    }

    exec { "unit_tests_${service_name}":
        command     => "/usr/bin/busted --helper=${config_prefix}/lua/mock.helper.lua --lpath=${config_prefix}/lua/?.lua ${config_prefix}/lua/*",
        refreshonly => true,
        require     => File["${config_prefix}/lua/mock.helper.lua"],
    }

    # When a reload is issued, Traffic Server checks if config files have
    # changed before acting. The Lua files are not tracked though, so touch
    # remap.config to trigger an actual reload when we change a Lua script.
    exec { "trigger_lua_reload_${config_prefix}":
        command     => "/usr/bin/touch ${config_prefix}/remap.config",
        refreshonly => true,
    }
}
