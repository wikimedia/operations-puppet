# vim: set ts=4 et sw=4:
# ganglia.pp
#
# Parameters:
#  - $deaf:         Is the gmond process an aggregator
#  - $cname:            Cluster's name
#  - $location:         Machine's location
#  - $mcast_address:        Multicast "cluster" to join and send data on
#  - $authority_url:        URL used by gmond and gmetad
#  - $gridname:         Grid name used by gmetad
#  - $data_sources:     Hash of datasources used by gmetad (production only)
#  - $rra_sizes:        Round-robin archives sizes used by gmetad
#  - $rrd_rootdir:      Directory to store round-robin dbs used by gmetad
#  - $ganglia_servername:   Server name used by apache
#  - $ganglia_serveralias:  Server alias(es) used by apache
#  - $ganglia_webdir:       Path of web directory used by apache


class ganglia {

    # FIXME: remove after the ganglia module migration
    if (hiera('ganglia_class', 'new') == 'new') {

        include ganglia_new::monitor
        # FIXME: ugly, but without it bad things happen with check_ganglia
        $cname = $ganglia_new::monitor::cname
    }
    else {
        notice("Ganglia disabled here")
    }
}
