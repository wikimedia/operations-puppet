# @summary profile for collecting netbox host data
# @param status the netbox status of the host or unknown
# @param location location data including site and cluster
class profile::netbox::host (
    Netbox::Host::Status             $status   = lookup('profile::netbox::host::status'),
    Optional[Netbox::Host::Location] $location = lookup('profile::netbox::host::location'),
) {
    unless $status == 'active' {
        warning("${facts['networking']['fqdn']} is ${status} in netbox")
    }
    unless $location {
        warning("${facts['networking']['fqdn']}: no netbox location found")
    } else {
        $message = $location ? {
            Netbox::Host::Location::Virtual => "Virtual Machine on Ganeti cluster: ${location['ganeti_cluster']}",
            default                         => "Bare Metal Rack: ${location['rack']}",
        }
        motd::message { 'netbox location':
            message => $message,
        }
    }
}

