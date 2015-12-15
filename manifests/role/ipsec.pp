class role::ipsec ($hosts = undef) {
    include strongswan::monitoring::host
    $puppet_certname = $::fqdn

    if $hosts != undef {
        $targets = $hosts
    } else {
        if $::hostname =~ /^cp/ {
            # if $cluster == 'cache_text', $ipsec_cluster = 'cache::ipsec::text'
            # This duplication of nodelist data in the ::ipsec:: case in
            # hieradata is so that we can depool cache nodes in the primary
            # hieradata lists without de-configuring the ipsec associations,
            # which could cause a traffic-leaking race.  This will go away once
            # etcd replaces hieradata comments for varnish-level depooling.

            $ipsec_cluster = regsubst(hiera('cluster'), '_', '::ipsec::')
            $cluster_nodes = hiera("${ipsec_cluster}::nodes")
            $kafka_nodes = hiera('cache::ipsec::kafka::nodes')

            # tier-2 sites associate with tier-1 kafka and tier-1 same-cluster cache nodes
            if $::site == 'esams' or $::site == 'ulsfo' or $::site == 'codfw' {
                $targets = array_concat(
                    $cluster_nodes['eqiad'],
                    $kafka_nodes['eqiad'],
                )

            }
            # tier-1 sites associate with tier-2 same-cluster cache nodes
            if $::site == 'eqiad' {
                $targets = array_concat(
                    $cluster_nodes['esams'],
                    $cluster_nodes['ulsfo'],
                    $cluster_nodes['codfw']
                )
            }
        } else if $hostname =~ /^kafka10/ {
            # kafka brokers (only in eqiad for now) associate with all tier-two caches
            $text    = hiera('cache::ipsec::text::nodes')
            $misc    = hiera('cache::ipsec::misc::nodes')
            $upload  = hiera('cache::ipsec::upload::nodes')
            $mobile  = hiera('cache::ipsec::mobile::nodes')
            $targets = array_concat(
                $text['esams'], $text['ulsfo'], $text['codfw'],
                $misc['esams'], $misc['ulsfo'], $misc['codfw'],
                $upload['esams'], $upload['ulsfo'], $upload['codfw'],
                $mobile['esams'], $mobile['ulsfo'], $mobile['codfw']
            )
        }
    }

    class { '::strongswan':
        puppet_certname => $puppet_certname,
        hosts           => $targets
    }
}
