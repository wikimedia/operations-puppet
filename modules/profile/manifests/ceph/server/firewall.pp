# SPDX-License-Identifier: Apache-2.0
# Class: profile::ceph::server::firewall
#
# This profile configures hosts that run Ceph services
class profile::ceph::server::firewall (
  Hash[String,Hash]                    $mon_hosts             = lookup('profile::ceph::mon::hosts'),
  Hash[String,Hash]                    $osd_hosts             = lookup('profile::ceph::osd::hosts'),
  Array[Stdlib::IP::Address]           $public_networks       = lookup('profile::ceph::public_networks'),
) {
    # These are the IPv4 addresses of the mon servers
    $mon_addrs = $mon_hosts.map | $key, $value | { $value['public']['addr'] }

    # These are the IPv4 addresses of the osd servers.
    # n.b. for the new Ceph cluster these are co-located with the OSD servers.
    $osd_public_addrs  = $osd_hosts.map | $key, $value | { $value['public']['addr'] }

    # OSD nodes may or may not have a separate cluster network.
    $osd_cluster_addrs = $osd_hosts.filter | $key, $value | {
      has_key($value,cluster)
    }.map | $key, $value | {
      $value['cluster']['addr']
    }

    # Remove duplicates for co-located mon and osd nodes
    $ceph_server_addrs = unique([$mon_addrs,$osd_public_addrs, $osd_cluster_addrs]).flatten

    # We need to open the Ceph ports to the ds-k8s workers as well, since the csi-rbdplugin
    # runs with host networking. Therefore it is not covered by the DSE_KUBEPODS_NETWORK src_set.
    $dse_k8s_workers_ips = wmflib::role::ips('dse_k8s::worker')

    firewall::service { 'ceph_daemons':
        proto      => 'tcp',
        port_range => [6800, 7300],
        srange     => $ceph_server_addrs + $dse_k8s_workers_ips,
        src_sets   => ['DSE_KUBEPODS_NETWORKS'],
        before     => Class['ceph::common'],
    }
    firewall::service { 'ceph_mon_v1':
        proto    => 'tcp',
        port     => 6789,
        srange   => $ceph_server_addrs + $dse_k8s_workers_ips,
        src_sets => ['DSE_KUBEPODS_NETWORKS'],
        before   => Class['ceph::common'],
    }
    firewall::service { 'ceph_mon_v2':
        proto    => 'tcp',
        port     => 3300,
        srange   => $ceph_server_addrs + $dse_k8s_workers_ips,
        src_sets => ['DSE_KUBEPODS_NETWORKS'],
        before   => Class['ceph::common'],
    }
}
