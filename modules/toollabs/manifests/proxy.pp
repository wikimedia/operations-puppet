class toollabs::proxy inherits toollabs {
    include toollabs::infrastructure

    $apaches = [ 'tools-webserver-01.pmtpa.wmflabs',
                 'tools-webserver-02.pmtpa.wmflabs',
                 'tools-webserver-03.pmtpa.wmflabs'
               ]
    # When the proxy's routing tables return nothing, pass on
    # the request to one of the webserver apaches.
    class ::dynamicproxy {
        notfound_servers => $apaches
    }
}
