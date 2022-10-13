# @summary profile for collecting netbox host data
# @param status the netbox status of the host or unknown
# @param location location data including site and cluster
class profile::netbox::host (
    Netbox::Host::Status             $status   = lookup('profile::netbox::host::status'),
    Optional[Netbox::Host::Location] $location = lookup('profile::netbox::host::location'),
) {
    unless $status == 'active' {
        warning("${facts['networking']['fqdn']} is ${status} in Netbox")
    }
    $_status = $status ? {
        'active' => wmflib::ansi::fg($status, 'green'),
        'staged' => wmflib::ansi::fg($status, 'yellow').wmflib::ansi::attr('bold'),
        default  => wmflib::ansi::fg($status, 'red'),
    }
    motd::message { 'netbox status':
        message  => "Netbox Status: ${_status}",
        priority => 1,
    }
    unless $location {
        warning("${facts['networking']['fqdn']}: no Netbox location found")
    } else {
        $message = $location ? {
            Netbox::Host::Location::Virtual => "Virtual Machine on Ganeti cluster ${location['ganeti_cluster']} and group ${location['ganeti_group']}",
            default                         => "Bare Metal host on site ${location['site']} and rack ${location['rack']}",
        }
        motd::message { 'netbox location':
            message => $message,
        }
    }
}

