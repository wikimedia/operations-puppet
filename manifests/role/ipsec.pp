class role::ipsec ($hosts = undef) {
    include strongswan::monitoring::host

    case $::realm {
        'labs': {
            # labs nodes use their EC2 ID as their puppet cert name
            $puppet_certname = "${::ec2id}.${::domain}"
        }
        default: {
            $puppet_certname = $::fqdn
        }
    }

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
        if $::site == 'esams' or $::site == 'ulsfo' {
            $targets = concat(
                $cluster_nodes['eqiad'],
                $cluster_nodes['codfw']
            )
        }
        # for 'left' nodes in "main" sites, enumerate 'right' nodes in cache sites
        if $::site == 'eqiad' or $::site == 'codfw' {
            $targets = concat(
                $cluster_nodes['esams'],
                $cluster_nodes['ulsfo']
            )
        }
    }

    class { '::strongswan':
        puppet_certname => $puppet_certname,
        hosts           => $targets
    }
}
