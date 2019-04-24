class role::ipsec ($hosts = undef) {
    include strongswan::monitoring::host
    $puppet_certname = $::fqdn

    if $hosts != undef {
        $targets = $hosts
    } else {
        # The cache-cluster ipsec associations are still manually-defined, so
        # any changes to cache cluster routing schemes beyond our present
        # plans (which only have codfw or eqiad backing other caches) must
        # make changes here to secure the traffic.
        # The current ipsec association scheme below is basically:
        #    eqiad <=> codfw
        #    eqiad+codfw <=> esams+ulsfo+eqsin

        if $::hostname =~ /^cp/ {
            $ipsec_cluster = hiera('cache::cluster')
            $cluster_nodes = hiera('cache::nodes')[$ipsec_cluster]

            if $::site == 'esams' or $::site == 'ulsfo' or $::site == 'eqsin' {
                $targets = array_concat(
                    $cluster_nodes['eqiad'],
                    $cluster_nodes['codfw']
                )
            } elsif $::site == 'codfw' {
                $targets = array_concat(
                    $cluster_nodes['esams'],
                    $cluster_nodes['ulsfo'],
                    $cluster_nodes['eqsin'],
                    $cluster_nodes['eqiad']
                )
            } elsif $::site == 'eqiad' {
                $targets = array_concat(
                    $cluster_nodes['esams'],
                    $cluster_nodes['ulsfo'],
                    $cluster_nodes['eqsin'],
                    $cluster_nodes['codfw']
                )
            }
        }
    }
    # Change the MTU for all cp* servers, ignore the rest (mc*, etc)
    if $::hostname =~ /^cp/ {
        $mtu_value = 1450
    } else {
        $mtu_value = undef
    }

    class { '::strongswan':
        puppet_certname => $puppet_certname,
        hosts           => $targets,
        mtu_hosts       => $mtu_value,
    }
}
