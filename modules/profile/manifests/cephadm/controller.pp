# SPDX-License-Identifier: Apache-2.0
# Class: profile::cephadm::controller
#
# This profile is for the node on which cephadm is installed (and thus
# is used to setup and manage the rest of the Ceph cluster).
class profile::cephadm::controller(
    Cephadm::Clusters $cephadm_clusters = lookup('cephadm_clusters'),
    String $cephadm_cluster_label       = lookup('profile::cephadm::cluster_label'),
    Optional[String] $ceph_repository_component =
    lookup('profile::cephadm::cephadm_component', { default_value => undef }),
) {
    require profile::cephadm::target
    require profile::netbox::data

    $osds = $cephadm_clusters[$cephadm_cluster_label]['osds']
    $monitors = $cephadm_clusters[$cephadm_cluster_label]['monitors']
    if 'rgws' in $cephadm_clusters[$cephadm_cluster_label] {
        $rgws = $cephadm_clusters[$cephadm_cluster_label]['rgws']
        $rgw_realm = $cephadm_cluster_label
    } else {
        $rgws = []
        $rgw_realm = undef
    }
    $cluster_nodes = unique($monitors + $osds + $rgws)
    $mon_network = $cephadm_clusters[$cephadm_cluster_label]['mon_network']

    $host_details = puppetdb::query_facts(
        ['ipaddress6','blockdevice_nvme0n1_model'],
        # HACK: PQL requires quotes around string array members
        "certname in ${cluster_nodes.to_json}"
    )

    # Look up OSD rack locations - the hash is keyed by management hostname
    # So we construct that first (by inserting "mgmt").
    $rack_locations = $osds.reduce( {} ) |$memo, $hostname| {
        $hn_array = $hostname.split('.')
        $management_hostname = join(flatten([ $hn_array[0], 'mgmt', $hn_array[1,-1] ]),'.')
        $memo + { $hostname => $profile::netbox::data::mgmt["$management_hostname"]['rack'] }
        }

    # cephadm::cephadm has a sensible default repository component,
    # only override it if hiera specifies something else
    if $ceph_repository_component {
        class { 'cephadm::cephadm':
            osds                      => $osds,
            mons                      => $monitors,
            rgws                      => $rgws,
            host_details              => $host_details,
            rack_locations            => $rack_locations,
            mon_network               => $mon_network,
            rgw_realm                 => $rgw_realm,
            ceph_repository_component => $ceph_repository_component,
        }
    } else {
        class { 'cephadm::cephadm':
            osds           => $osds,
            mons           => $monitors,
            rgws           => $rgws,
            host_details   => $host_details,
            rack_locations => $rack_locations,
            mon_network    => $mon_network,
            rgw_realm      => $rgw_realm,
        }
    }
}
