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
    $ceph_server_addrs = unique([$mon_addrs,$osd_public_addrs, $osd_cluster_addrs])

    # TODO - In order to make this profile work for any ceph cluster, we will need a flexible mechanism
    # of specifying which client hosts and networks can access the daemons. In the cloudceph profiles,
    # from which these drew inspiration, there were a number of client IP ranges configured and different
    # server roles, such as cinder backup hosts, cloudstack controllers etc. For the new ceph cluster the
    # only known client networks will be the DSE-K8S pod range, since the radosgw clients are co-located
    # with the OSDs and mon processes.
    #
    # During this bootstrapping phase we will therefore only allow server traffic from within the cluster
    # and will return to the configuration mechanism for RBD client networks, such as the dse-k8s cluster
    # pod ranges.
    $ferm_srange = join($ceph_server_addrs, ' ')

    ferm::service { 'ceph_daemons':
        proto      => 'tcp',
        port_range => [6800, 7300],
        srange     => "(${ferm_srange})",
        before     => Class['ceph::common'],
    }
    ferm::service { 'ceph_mon_v1':
      proto  => 'tcp',
      port   => 6789,
      srange => "(${ferm_srange})",
      before => Class['ceph::common'],
    }
    ferm::service { 'ceph_mon_v2':
      proto  => 'tcp',
      port   => 3300,
      srange => "(${ferm_srange})",
      before => Class['ceph::common'],
    }
}
