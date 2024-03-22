# SPDX-License-Identifier: Apache-2.0
# Class: profile::cloudceph::mon
#
# This profile configures Ceph monitor hosts with the mon and mgr daemons
class profile::cloudceph::mon(
    Hash[String,Hash]          $mon_hosts                 = lookup('profile::cloudceph::mon::hosts'),
    Hash[String,Hash]          $osd_hosts                 = lookup('profile::cloudceph::osd::hosts'),
    Array[Stdlib::IP::Address] $cluster_networks          = lookup('profile::cloudceph::cluster_networks'),
    Array[Stdlib::IP::Address] $public_networks           = lookup('profile::cloudceph::public_networks'),
    Stdlib::Unixpath           $data_dir                  = lookup('profile::cloudceph::data_dir'),
    String                     $fsid                      = lookup('profile::cloudceph::fsid'),
    String                     $ceph_repository_component = lookup('profile::cloudceph::ceph_repository_component'),
    Array[Stdlib::Fqdn]        $cinder_backup_nodes       = lookup('profile::cloudceph::cinder_backup_nodes'),
    Ceph::Auth::Conf           $ceph_auth_conf            = lookup('profile::cloudceph::auth::load_all::configuration'),
) {
    require 'profile::cloudceph::auth::load_all'

    include network::constants

    # this selects all production networks in eqiad & codfw that have a private subnet with name
    # cloud-host that contains an 'ipv4' attribute
    $client_networks = ['eqiad', 'codfw'].map |$dc| {
        $network::constants::all_network_subnets['production'][$dc]['private'].filter | $subnet | {
            $subnet[0] =~ /cloud-hosts/
        }.map | $subnet, $value | {
            $value['ipv4']
        }
    }.flatten.delete_undef_values.sort

    # Make sure the mgr keyring dir has the right permissions
    $keyring_path = ceph::auth::get_keyring_path("mgr.${::hostname}", $ceph_auth_conf["mgr.${::hostname}"]['keyring_path'])

    # if nobody defined it yet, set permissions on the parent dirs (copied from mkdir_p.pp)
    $_dirs = wmflib::dir::normalise($keyring_path)
    $parents = wmflib::dir::split($_dirs) - $_dirs
    $parents.each |$parent_dir| {
        # avoid touching the data_dir and it's parents too
        if !defined(File[$parent_dir]) and ($parent_dir !~ Regexp("^${data_dir}$")) and ($data_dir !~ Regexp("^${parent_dir}/.*")) {
            file { $parent_dir:
                ensure => directory,
                mode   => '0750',
                owner  => 'ceph',
                group  => 'ceph',
            }
        }
    }

    $mon_addrs = $mon_hosts.map | $key, $value | { $value['public']['addr'] }
    $osd_public_addrs = $osd_hosts.map | $key, $value | { $value['public']['addr'] }

    $firewall_srange = $mon_addrs + $osd_public_addrs + $client_networks + $cinder_backup_nodes
    firewall::service { 'ceph_mgr_v2':
        proto  => 'tcp',
        port   => 6800,
        srange => $firewall_srange,
        before => Class['ceph::common'],
    }
    firewall::service { 'ceph_mgr_v1':
        proto  => 'tcp',
        port   => 6801,
        srange => $firewall_srange,
        before => Class['ceph::common'],
    }
    firewall::service { 'ceph_mon_peers_v1':
        proto  => 'tcp',
        port   => 6789,
        srange => $firewall_srange,
        before => Class['ceph::common'],
    }
    firewall::service { 'ceph_mon_peers_v2':
        proto  => 'tcp',
        port   => 3300,
        srange => $firewall_srange,
        before => Class['ceph::common'],
    }

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
    }

    class { 'ceph::mon':
        data_dir   => $data_dir,
        fsid       => $fsid,
        admin_auth => $ceph_auth_conf['admin'],
        mon_auth   => $ceph_auth_conf["mon.${::hostname}"],
    }

    Class['ceph::mon'] -> Class['ceph::mgr']

    class { 'ceph::mgr':
        data_dir => $data_dir,
        mgr_auth => $ceph_auth_conf["mgr.${::hostname}"],
    }

    $mon_host_ips = $mon_hosts.reduce({}) | $memo, $value | {
        $memo + {$value[0] => $value[1]['public']['addr'] }
    }
    $osd_public_host_ips = $osd_hosts.reduce({}) | $memo, $value | {
        $memo + {$value[0] => $value[1]['public']['addr'] }
    }
    # This adds latency stats between from this mon to the rest of the ceph fleet
    class { 'prometheus::node_pinger':
        nodes_to_ping_regular_mtu => $mon_host_ips + $osd_public_host_ips,
    }

    # Allow ceph user to collect device health metrics
    # We don't actually want to do this on a mon node,
    # but for now this patch will keep us from getting emails
    # about sudo violations
    #  Upstream bug: https://tracker.ceph.com/issues/50657
    # This sudo change can be removed when ^ is fixed (in v15.2.16)
    sudo::user { 'ceph-smartctl':
      user       => 'ceph',
      privileges => [
        'ALL=NOPASSWD: /usr/sbin/smartctl -a --json=o /dev/*',
        'ALL=NOPASSWD: /usr/sbin/nvme * smart-log-add --json /dev/*',
      ],
    }
}
