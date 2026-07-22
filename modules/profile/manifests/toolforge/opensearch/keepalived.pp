# SPDX-License-Identifier: Apache-2.0
class profile::toolforge::opensearch::keepalived (
    Opensearch::InstanceParams $opensearch_settings = lookup('profile::opensearch::common_settings'),
    Array[Stdlib::Host, 1]     $vips                = lookup('profile::toolforge::opensearch::keepalived::vips'),
    String[1]                  $auth_pass           = lookup('profile::toolforge::opensearch::keepalived::password'),
) {
    $peers = $opensearch_settings['cluster_hosts']
        .delete($facts['networking']['fqdn'])
        .wmflib::hosts2ips()

    class { 'keepalived::failover':
        auth_pass => $auth_pass,
        peers     => $peers,
        vips      => $vips.wmflib::hosts2ips(),
    }

    nftables::service { 'keepalived':
        proto   => 'vrrp',
        src_ips => $peers,
    }
}
