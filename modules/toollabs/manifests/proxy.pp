# A dynamic HTTP routing proxy, based on the dynamicproxy module.
class toollabs::proxy inherits toollabs {
    include toollabs::infrastructure

    class { '::dynamicproxy':
        luahandler => 'urlproxy.lua',
        resolver   => '10.68.16.1' # eqiad DNS resolver
    }

    package { 'python-redis':
        ensure => present
    }
}
