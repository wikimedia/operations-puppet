# Class: profile::ceph::osd
#
# This profile configures Ceph object storage hosts with the osd daemon
class profile::ceph::osd(
    Array[Stdlib::Fqdn]        $openstack_controllers           = lookup('profile::ceph::openstack_controllers'),
    Hash[String[1],Hash]       $mon_hosts                       = lookup('profile::ceph::mon::hosts'),
    Hash[String[1],Hash]       $osd_hosts                       = lookup('profile::ceph::osd::hosts'),
    Stdlib::IP::Address        $cluster_network                 = lookup('profile::ceph::cluster_network'),
    Stdlib::IP::Address        $public_network                  = lookup('profile::ceph::public_network'),
    Stdlib::Unixpath           $data_dir                        = lookup('profile::ceph::data_dir'),
    String[1]                  $fsid                            = lookup('profile::ceph::fsid'),
    Array[String[1]]           $disk_models_without_write_cache = lookup('profile::ceph::osd::disk_models_without_write_cache'),
    Array[String[1]]           $os_disks                        = lookup('profile::ceph::osd::os_disks'),
    String[1]                  $disks_io_scheduler              = lookup('profile::ceph::osd::disks_io_scheduler', { default_value => 'mq-deadline'}),
    String[1]                  $ceph_repository_component       = lookup('profile::ceph::ceph_repository_component'),
    Array[Stdlib::Fqdn]        $cinder_backup_nodes             = lookup('profile::ceph::cinder_backup_nodes'),
    Array[Stdlib::IP::Address] $osd_cluster_networks            = lookup('profile::ceph::osd::cluster_networks')
) {
    $cluster_iface = $osd_hosts[$facts['fqdn']]['cluster']['iface']

    require profile::ceph::auth::deploy
    if ! defined(Ceph::Auth::Keyring['admin']) {
        notify{'profile::ceph::osd: Admin keyring not defined, things might not work as expected.': }
    }
    if ! defined(Ceph::Auth::Keyring['bootstrap-osd']) {
        notify{'profile::ceph::osd: bootstrap-osd keyring not defined, things might not work as expected.': }
    }

    # Ceph OSDs should use the performance governor, not the default 'powersave'
    # governor
    class { 'cpufrequtils': }

    # Each ceph osd server runs multiple daemons, each daemon listens on 6 ports
    # The ports can range anywhere between 6800 and 7100. This can be controlled
    # with the `ms bind port min` and `ms bind port max` ceph config parameters.

    # The cluster interface is used for OSD data replication and heartbeat network traffic
    interface::manual{ 'osd-cluster':
        interface => $cluster_iface,
    }
    interface::ip { 'osd-cluster-ip':
        interface => $cluster_iface,
        address   => $osd_hosts[$facts['fqdn']]['cluster']['addr'],
        prefixlen => $osd_hosts[$facts['fqdn']]['cluster']['prefix'],
        require   => Interface::Manual['osd-cluster'],
        before    => Class['ceph::common'],
    }
    # did not find a nice way to use facts instead of the extra unless command
    # as facter -p net_driver shows speed -1 for VMs even when the interface is up
    exec { 'bring-cluster-interface-up':
        command => "/usr/sbin/ip link set ${cluster_iface} up",
        unless  => "/usr/sbin/ip link show ${cluster_iface} | grep -q UP",
        require => Interface::Ip['osd-cluster-ip'],
    }

    # Tune the MTU on both the cluster and public network
    interface::setting { 'osd-cluster-mtu':
        interface => $cluster_iface,
        setting   => 'mtu',
        value     => '9000',
        before    => Class['ceph::common'],
        notify    => Exec['set-osd-cluster-mtu'],
    }
    interface::setting { 'osd-public-mtu':
        interface => $cluster_iface,
        setting   => 'mtu',
        value     => '9000',
        before    => Class['ceph::common'],
        notify    => Exec['set-osd-public-mtu'],
    }
    # Make sure the interface is in sync with configuration changes
    exec { 'set-osd-cluster-mtu':
        command     => "/usr/sbin/ip link set mtu 9000 ${cluster_iface}",
        refreshonly => true,
    }
    exec { 'set-osd-public-mtu':
        command     => "/usr/sbin/ip link set mtu 9000 ${cluster_iface}",
        refreshonly => true,
    }

    $ferm_cluster_srange = join($osd_hosts.map | $key, $value | { $value['cluster']['addr'] }, ' ')
    ferm::service { 'ceph_osd_cluster_range':
        proto  => 'tcp',
        port   => '6800:7100',
        srange => "(${ferm_cluster_srange})",
        drange => $osd_hosts[$facts['fqdn']]['cluster']['addr'],
        before => Class['ceph::common'],
    }


    # Set a static route with the gateway to the rest of the osds networks
    # We are assuming /24 for each network, and .254 to be the GW
    $osd_cluster_networks.each | Stdlib::IP::Address $cluster_network | {
        $cur_ip_chunks = split($osd_hosts[$facts['fqdn']]['cluster']['addr'], '[.]')
        $cur_network_chunks = $cur_ip_chunks[0, -2]
        $cur_network_substring = join($cur_network_chunks, '.')
        $new_ip_chunks = split($cluster_network, '[.]')
        $new_network_chunks = $new_ip_chunks[0, -2]
        $new_network_substring = join($new_network_chunks, '.')
        # skip your own network
        if $cur_network_substring != $new_network_substring {
            # the gw to the other network is through the current network .254
            $gw_address = "${cur_network_substring}.254"
            interface::route { "route_to_${join($new_network_chunks, '_')}_0":
                address   => $cluster_network,
                nexthop   => $gw_address,
                prefixlen => 24,
                require   => Interface::Ip['osd-cluster-ip'],
            }
        }
    }

    include network::constants

    $client_networks = [
        $network::constants::all_network_subnets['production']['eqiad']['private']['cloud-hosts1-eqiad']['ipv4'],
        $network::constants::all_network_subnets['production']['eqiad']['private']['cloud-hosts1-e4-eqiad']['ipv4'],
        $network::constants::all_network_subnets['production']['eqiad']['private']['cloud-hosts1-f4-eqiad']['ipv4'],
        $network::constants::all_network_subnets['production']['codfw']['private']['cloud-hosts1-codfw']['ipv4'],
    ]

    $mon_addrs = $mon_hosts.map | $key, $value | { $value['public']['addr'] }
    $osd_addrs = $osd_hosts.map | $key, $value | { $value['public']['addr'] }
    $openstack_controller_ips = $openstack_controllers.map |$host| { ipresolve($host, 4) }
    $cinder_backup_nodes_ips  = $cinder_backup_nodes.map |$host| { ipresolve($host, 4) }
    $ferm_public_srange = join(concat($mon_addrs, $osd_addrs, $client_networks, $openstack_controller_ips, $cinder_backup_nodes_ips), ' ')
    ferm::service { 'ceph_osd_range':
        proto  => 'tcp',
        port   => '6800:7100',
        srange => "(${ferm_public_srange})",
        drange => $osd_hosts[$facts['fqdn']]['public']['addr'],
        before => Class['ceph::common'],
    }

    class { 'ceph::common':
        home_dir                  => $data_dir,
        ceph_repository_component => $ceph_repository_component,
    }

    class { 'ceph::config':
        cluster_network     => $cluster_network,
        enable_libvirt_rbd  => false,
        enable_v2_messenger => true,
        fsid                => $fsid,
        mon_hosts           => $mon_hosts,
        osd_hosts           => $osd_hosts,
        public_network      => $public_network,
    }

    # This adds latency stats between from this osd to the rest of the ceph fleet
    class { 'prometheus::node_pinger':
        nodes_to_ping => $osd_hosts.keys() + $mon_hosts.keys(),
    }

    $facts['disks'].each |String $device, Hash $device_info| {
        if ! ( $device in $os_disks) {
            if ('model' in $device_info and $device_info['model'] in $disk_models_without_write_cache) {
                exec { "Disable write cache on device /dev/${device}":
                    # 0->disable, 1->enable
                    command => "hdparm -W 0 /dev/${device}",
                    user    => 'root',
                    unless  => "hdparm -W /dev/${device} | grep write-caching | grep -q off",
                    path    => ['/usr/sbin', '/usr/bin'],
                }
            }

            exec { "Set IO scheduler on device /dev/${device} to ${disks_io_scheduler}":
                command => "echo ${disks_io_scheduler} > /sys/block/${device}/queue/scheduler",
                user    => 'root',
                unless  => "grep -q '\\[${disks_io_scheduler}\\]' /sys/block/${device}/queue/scheduler",
                path    => ['/usr/sbin', '/usr/bin'],
            }
        }
    }
}
