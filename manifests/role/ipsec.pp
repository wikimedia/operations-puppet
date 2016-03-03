class role::ipsec ($hosts = undef) {
    include strongswan::monitoring::host
    $puppet_certname = $::fqdn

    if $hosts != undef {
        $targets = $hosts
    } else {
        if $::hostname =~ /^cp/ {
            $ipsec_cluster = regsubst(hiera('cluster'), '_', '::')
            $cluster_nodes = hiera("${ipsec_cluster}::nodes")
            $kafka_nodes = hiera('cache::ipsec::kafka::nodes')

            # tier-2 sites associate with tier-1 kafka and tier-1 same-cluster cache nodes
            if $::site == 'esams' or $::site == 'ulsfo' or $::site == 'codfw' {
                $targets = array_concat(
                    $cluster_nodes['eqiad'],
                    $kafka_nodes['eqiad']
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
        } elsif $::hostname =~ /^kafka10/ {
            # kafka brokers (only in eqiad for now) associate with all tier-two caches
            $text    = hiera('cache::ipsec::text::nodes')
            $misc    = hiera('cache::ipsec::misc::nodes')
            $upload  = hiera('cache::ipsec::upload::nodes')
            $targets = array_concat(
                $text['esams'], $text['ulsfo'], $text['codfw'],
                $misc['esams'], $misc['ulsfo'], $misc['codfw'],
                $upload['esams'], $upload['ulsfo'], $upload['codfw']
            )
        }
    }

    class { '::strongswan':
        puppet_certname => $puppet_certname,
        hosts           => $targets
    }
}
