class trafficserver::lua_infra {
    require_package('lua-busted')

    exec { 'unit_tests':
        command     => '/usr/bin/busted --lpath=/etc/trafficserver/lua/?.lua /etc/trafficserver/lua/*',
        refreshonly => true,
    }

    # When a reload is issued, Traffic Server checks if config files have
    # changed before acting. The Lua files are not tracked though, so touch
    # remap.config to trigger an actual reload when we change a Lua script.
    exec { 'trigger_lua_reload':
        command     => '/usr/bin/touch /etc/trafficserver/remap.config',
        refreshonly => true,
    }

    file { '/etc/trafficserver/lua/':
        ensure => directory,
        mode   => '0755',
        owner  => $trafficserver::user,
    }
}
