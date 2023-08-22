# SPDX-License-Identifier: Apache-2.0
# @param ca_server the CA server
# @param swift_clusters instance of Swift::Clusters (hash of cluster info)
# @param volatile_dir the location of the volatile dir
class profile::swift::fetch_rings (
    Stdlib::Host     $ca_server      = lookup('puppet_ca_server'),
    Swift::Clusters  $swift_clusters = lookup('swift_clusters'),
    Stdlib::Unixpath $volatile_dir   = lookup('profile::swift::fetch_rings::volatile_dir'),
) {
    $ca = $ca_server == $facts['networking']['fqdn']
    $ring_fetch = stdlib::ensure($ca)
    $swift_dir = "${volatile_dir}/swift"
    file { $swift_dir:
        ensure => directory,
    }

    $swift_clusters.each |String $sc, Swift::Cluster_info $sc_info| {
        if $sc_info['ring_manager'] != undef {
            $cluster_dir = "${swift_dir}/${sc_info['cluster_name']}"
            file { $cluster_dir:
                ensure => directory,
            }
            systemd::timer::job { "fetch-rings-${sc}":
                ensure          => stdlib::ensure($ca),  # We only want the timer to run on one host, use ca
                user            => 'root',
                description     => "rsync swift rings from cluster ${sc}",
                command         => "/usr/bin/rsync -bcptz ${sc_info['ring_manager']}::swiftrings/new_rings.tar.bz2 ${cluster_dir}/",
                interval        => {'start' => 'OnCalendar', 'interval' => '*:5/20:00'},
                logging_enabled => false,
            }
        }
    }

}
