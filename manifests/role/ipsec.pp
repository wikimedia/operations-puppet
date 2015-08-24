class role::ipsec ($hosts = undef) {
    include strongswan::monitoring::host
    $puppet_certname = $::fqdn

    if $hosts != undef {
        $targets = $hosts
    } else {
        # if $cluster == 'cache_text', $ipsec_cluster = 'cache::ipsec::text'
        # This duplication of nodelist data in the ::ipsec:: case in
        # hieradata is so that we can depool cache nodes in the primary
        # hieradata lists without de-configuring the ipsec associations,
        # which could cause a traffic-leaking race.  This will go away once
        # etcd replaces hieradata comments for varnish-level depooling.

        $ipsec_cluster = regsubst(hiera('cluster'), '_', '::ipsec::')
        $cluster_nodes = hiera("${ipsec_cluster}::nodes")
        # for 'left' nodes in cache sites, enumerate 'right' nodes in "main" sites

        # Note codfw tier2, which isn't controlled by $site_tier... T110065
        if $::site == 'esams' or $::site == 'ulsfo' or $::site == 'codfw' {
            $targets = $cluster_nodes['eqiad']
        }
        # for 'left' nodes in "main" sites, enumerate 'right' nodes in cache sites
        if $::site == 'eqiad' {
            $targets = concat(
                $cluster_nodes['esams'],
                $cluster_nodes['ulsfo'],
                $cluster_nodes['codfw']
            )
        }
    }

    class { '::strongswan':
        puppet_certname => $puppet_certname,
        hosts           => $targets
    }
}
