# SPDX-License-Identifier: Apache-2.0
# == Class: trafficserver::lua_infra
#
# Sets up the required resources to run Lua scripts in Trafficserver.
#
class trafficserver::lua_infra {
    stdlib::ensure_packages('lua-busted')

    file { '/etc/trafficserver/lua':
        ensure => directory,
        mode   => '0755',
        owner  => $trafficserver::user,
    }

    file { '/etc/trafficserver/lua/mock.helper.lua':
        ensure => present,
        owner  => $trafficserver::user,
        source => 'puppet:///modules/profile/trafficserver/mock.helper.lua',
    }

    exec { 'trafficserver_lua_unit_tests':
        command     => '/usr/bin/busted --helper=/etc/trafficserver/lua/mock.helper.lua --lpath=/etc/trafficserver/lua/?.lua /etc/trafficserver/lua/*',
        refreshonly => true,
        require     => File['/etc/trafficserver/lua/mock.helper.lua'],
    }

    # When a reload is issued, Traffic Server checks if config files have
    # changed before acting. The Lua files are not tracked though, so touch
    # remap.config to trigger an actual reload when we change a Lua script.
    exec { 'trafficserver_lua_reload':
        command     => '/usr/bin/touch /etc/trafficserver/remap.config',
        refreshonly => true,
    }
}
