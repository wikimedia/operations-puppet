# Define monitoring for all Anycast VIPs
# By their nature, those VIPs are advertized from several locations on the
# network. In its current state, Icinga can only alert if that IP is nowhere
# to be seen on the network. Not if the number of hosts advertizing that VIP
# falls under a certain threshold.
# The service check will only check the health of the server closest to Icinga
# in term of BGP distance (or multiple servers if load-balancing is enabled).

class profile::bird::anycast_monitoring{

    monitoring::host { 'recdns.anycast.wmnet':
        host_fqdn => 'recdns.anycast.wmnet',
    }

    monitoring::service { 'Recursive DNS anycast VIP':
        host          => 'recdns.anycast.wmnet',
        description   => 'recursive DNS anycast VIP',
        check_command => 'check_dns!www.wikipedia.org',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Anycast_recursive_DNS#Troubleshooting',
    }
}
