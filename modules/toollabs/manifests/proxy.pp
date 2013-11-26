# A dynamic HTTP routing proxy, based on the dynamicproxy module.
# When no route is found, passes on the request to one of the apaches.
class toollabs::proxy inherits toollabs {
    include toollabs::infrastructure

    $apaches = [ 'tools-webserver-01.pmtpa.wmflabs',
                 'tools-webserver-02.pmtpa.wmflabs',
                 'tools-webserver-03.pmtpa.wmflabs'
               ]

    class { '::dynamicproxy':
        notfound_servers => $apaches,
        luahandler => 'urlproxy.lua'
    }
}
