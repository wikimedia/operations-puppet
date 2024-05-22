# SPDX-License-Identifier: Apache-2.0
# Class: profile::ceph::core
#
# This profile provides common configuration for Ceph services.
    class profile::ceph::core (
    Hash[String,Hash]          $mon_hosts                 = lookup('profile::ceph::mon::hosts'),
    Hash[String,Hash]          $osd_hosts                 = lookup('profile::ceph::osd::hosts'),
    Array[Stdlib::IP::Address] $public_networks           = lookup('profile::ceph::public_networks'),
    Array[Stdlib::IP::Address] $cluster_networks          = lookup('profile::ceph::cluster_networks', { default_value => [] }),
    Stdlib::Unixpath           $data_dir                  = lookup('profile::ceph::data_dir', { default_value => '/var/lib/ceph' }),
    String                     $fsid                      = lookup('profile::ceph::fsid'),
    String                     $ceph_repository_component = lookup('profile::ceph::ceph_repository_component'),
    Stdlib::Port               $radosgw_port              = lookup('profile::ceph::radosgw::port'),
    ) {
    require profile::ceph::auth::load_all

    require profile::ceph::server::firewall

    class { 'ceph::common':
        home_dir                  => $data_dir,
        ceph_repository_component => $ceph_repository_component,
    }

    class { 'ceph::config':
        cluster_networks    => $cluster_networks,
        enable_libvirt_rbd  => false,
        enable_v2_messenger => true,
        fsid                => $fsid,
        mon_hosts           => $mon_hosts,
        osd_hosts           => $osd_hosts,
        public_networks     => $public_networks,
        rgw_frontend        => 'beast',
        radosgw_port        => $radosgw_port,
    }

    # TODO enable prometheus pinger
    # # These are the IPv4 addresses of the mon servers
    # $mon_addrs = $mon_hosts.map | $key, $value | { $value['public']['addr'] }

    # # These are the IPv4 addresses of the osd servers.
    # # n.b. for the new Ceph cluster these are co-located with the OSD servers.
    # $osd_public_addrs  = $osd_hosts.map | $key, $value | { $value['public']['addr'] }

    # # OSD nodes may or may not have a separate cluster network.
    # $osd_cluster_addrs = $osd_hosts.filter | $key, $value | {
    #   has_key($value,cluster)
    # }.map | $key, $value | {
    #   $value['cluster']['addr']
    # }

    # # Remove duplicates for co-located mon and osd nodes
    # $ceph_server_addrs = unique([$mon_addrs,$osd_public_addrs, $osd_cluster_addrs])

    # # This adds latency stats between from this osd to the rest of the ceph fleet
    # class { 'prometheus::node_pinger':
    #   nodes_to_ping_regular_mtu => $ceph_server_addrs,
    # }
}
