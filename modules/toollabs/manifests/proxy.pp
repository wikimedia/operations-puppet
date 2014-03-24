# A dynamic HTTP routing proxy, based on the dynamicproxy module.
class toollabs::proxy inherits toollabs {
    include toollabs::infrastructure

    class { '::dynamicproxy':
        luahandler       => 'urlproxy.lua'
    }
}
