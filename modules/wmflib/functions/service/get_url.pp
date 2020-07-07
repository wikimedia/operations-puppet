# This function returns the url for a service, supporting the use of the services proxy too.
# Parameters:
# [*svc_name*] The service name, as found in the service::catalog hiera variable or in the listeners list
# [*url*] The url path relative to the server name. Defaults to the empty string
# [*listeners*] An optional array of service proxy listeners. If provided, the url will be
#     pointed to the service proxy instead than directly to the load balancer.

function wmflib::service::get_url(String $svc_name, String $url = '', Optional[Array[Hash]] $listeners = undef) >> String {
    # We are using the service directly, no proxy
    if $listeners == undef {
        # service::catalog should contain $svc_name.
        $service = wmflib::service::fetch()[$svc_name]
        if $service == undef {
            fail("Service ${svc_name} not found in the catalog.")
        }
        if $service['discovery'] == undef {
            fail("Service ${svc_name} doesn't have a discovery record!")
        }
        $dns_label = $service['discovery'][0]['dnsdisc']
        $host = "${dns_label}.discovery.wmnet"
        $port = $service['port']
        $scheme = $service['encryption'] ? {
            true    => 'https',
            default => 'http'
        }
    } else {
        # We use the service proxy.
        $host = 'localhost'
        $related = $listeners.filter |$l| { $l['name'] == $svc_name }
        if $related.length() != 1 {
            fail("One and only one listener with name '${svc_name}' is expected")
        }
        $port = $related[0]['port']
        $scheme = 'http'
    }
    "${scheme}://${host}:${port}${url}"
}
