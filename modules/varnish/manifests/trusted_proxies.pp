# === Class varnish::trusted_proxies
#
# Creates /var/netmapper/trusted_proxies.json, a vmod_netmapper(3) database
# file containing the list of proxy server IP ranges we consider as trusted
# when it comes to using the information they provide in X-Forwarded-For to
# determine the actual client IP address.
#
# The file is stored as misc/trusted_proxies.json in the private puppet repo.
class varnish::trusted_proxies {
    file { '/var/netmapper/trusted_proxies.json':
        owner   => 'netmap',
        group   => 'netmap',
        mode    => '0444',
        content => secret('misc/trusted_proxies.json'),
    }
}
