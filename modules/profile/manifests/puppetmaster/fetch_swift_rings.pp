# SPDX-License-Identifier: Apache-2.0
# @param ca_server the CA server
# @param swift_clusters instance of Swift::Clusters (hash of cluster info)
class profile::puppetmaster::fetch_swift_rings (
    Stdlib::Host        $ca_server               = lookup('puppet_ca_server'),
    Swift::Clusters     $swift_clusters          = lookup('swift_clusters'),
) {
    $ca = $ca_server == $facts['networking']['fqdn']
    # The master frontend copies updated swift rings from each clusters'
    # ring management host into volatile
    $ring_fetch = $ca.bool2str('present', 'absent')

    $swift_clusters.each |String $sc, Swift::Cluster_info $sc_info| {
        if $sc_info['ring_manager'] != undef {
            systemd::timer::job { "fetch-rings-${sc}":
                ensure          => $ring_fetch,
                user            => 'root',
                description     => "rsync swift rings from cluster ${sc}",
                command         => "/usr/bin/rsync -bcptz ${sc_info['ring_manager']}::swiftrings/new_rings.tar.bz2 /var/lib/puppet/volatile/swift/${sc_info['cluster_name']}/",
                interval        => {'start' => 'OnCalendar', 'interval' => '*:5/20:00'},
                logging_enabled => false,
            }
        }
    }

}
