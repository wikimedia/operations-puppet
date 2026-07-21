# SPDX-License-Identifier: Apache-2.0
# Class: profile::cloudceph::osd
#
# This profile configures Ceph object storage hosts with the osd daemon
class profile::cloudceph::osd(
    Hash[String[1],Hash]        $mon_hosts                       = lookup('profile::cloudceph::mon::hosts'),
    Hash[String[1],Hash]        $osd_hosts                       = lookup('profile::cloudceph::osd::hosts'),
    Array[Stdlib::IP::Address]  $cluster_networks                = lookup('profile::cloudceph::cluster_networks'),
    Array[Stdlib::IP::Address]  $public_networks                 = lookup('profile::cloudceph::public_networks'),
    Stdlib::Unixpath            $data_dir                        = lookup('profile::cloudceph::data_dir'),
    String[1]                   $fsid                            = lookup('profile::cloudceph::fsid'),
    Array[String[1]]            $disk_models_without_write_cache = lookup('profile::cloudceph::osd::disk_models_without_write_cache'),
    Integer                     $num_os_disks                    = lookup('profile::cloudceph::osd::num_os_disks'),
    String[1]                   $disks_io_scheduler              = lookup('profile::cloudceph::osd::disks_io_scheduler', { default_value => 'mq-deadline'}),
    String[1]                   $ceph_repository_component       = lookup('profile::cloudceph::ceph_repository_component'),
    Array[Stdlib::Fqdn]         $cinder_backup_nodes             = lookup('profile::cloudceph::cinder_backup_nodes'),
    Boolean                     $with_location_hook              = lookup('profile::cloudceph::osd::with_location_hook'),
    Boolean                     $enable_qos                      = lookup('profile::cloudceph::osd::enable_qos'),
    Boolean                     $osd_enable_discard              = lookup('profile::cloudceph::osd::osd_enable_discard'),
    Profile::Wmcs::Vlan_Mapping $vlan_mapping                    = lookup('profile::wmcs::cloud_storage_subnet::vlan_mapping'),
    Netbox::Device::Location    $netbox_location                 = lookup('profile::netbox::host::location'),
    Integer                     $slow_ops_threshold              = lookup('profile::cloudceph::osd::slow_ops_threshold'),
    Integer                     $slow_ops_window_seconds         = lookup('profile::cloudceph::osd::slow_ops_window_seconds'),
) {
    $host_conf = $osd_hosts[$facts['networking']['fqdn']]

    $public_iface = $host_conf['public']['iface']
    $single_iface = pick($host_conf['cluster']['single_iface'], false)

    $rack = downcase($netbox_location['rack'])
    $vlan_id = $vlan_mapping[$::site][$rack]

    if $single_iface {
        $cluster_iface = "vlan${vlan_id}"
    } else {
        $cluster_iface = $host_conf['cluster']['iface']
    }

    require profile::cloudceph::auth::deploy
    if ! defined(Ceph::Auth::Keyring['admin']) {
        notify{'profile::cloudceph::osd: Admin keyring not defined, things might not work as expected.': }
    }
    if ! defined(Ceph::Auth::Keyring['bootstrap-osd']) {
        notify{'profile::cloudceph::osd: bootstrap-osd keyring not defined, things might not work as expected.': }
    }

    if ! ('pacific' in $ceph_repository_component) {
        # ceph-volume was included in the ceph-osd until Q.
        # since we aren't running anything older than P right now,
        # the simple check for Pacific should be good enough.
        ensure_packages(['ceph-volume'])
    }

    ensure_packages(['ceph-osd', 'python3-packaging'])

    # Ceph OSDs should use the performance governor, not the default 'powersave'
    # governor
    class { 'cpufrequtils': }

    # Handle transition from double to single NIC - T405478
    if $single_iface {
        $extra_iface = $host_conf['cluster']['iface']

        exec { 'bring-down-extra-iface':
            command => "/usr/sbin/ifdown ${extra_iface}",
            onlyif  => "/usr/sbin/ifquery ${extra_iface}",
        }

        augeas { 'unconfigure-extra-nic':
            incl    => '/etc/network/interfaces',
            lens    => 'Interfaces.lns',
            context => '/files/etc/network/interfaces',
            changes => [
                "rm iface[. = '${extra_iface}']",
            ],
        }
    }

    interface::tagged { "vlan${vlan_id}":
        base_interface => $public_iface,
        vlan_id        => $vlan_id,
        method         => 'manual',
        remove         => !$single_iface,
    }

    # The cluster interface is used for OSD data replication and heartbeat network traffic
    interface::manual{ 'osd-cluster':
        interface => $cluster_iface,
    }
    interface::ip { 'osd-cluster-ip':
        interface => $cluster_iface,
        address   => $host_conf['cluster']['addr'],
        prefixlen => $host_conf['cluster']['prefix'],
        require   => Interface::Manual['osd-cluster'],
        before    => Class['ceph::common'],
    }

    exec { 'bring-cluster-interface-up':
        command => "/usr/sbin/ip link set ${cluster_iface} up",
        unless  => "/usr/sbin/ip link show ${cluster_iface} | grep -q UP",
        require => Interface::Ip['osd-cluster-ip'],
    }

    # Tune the MTU on both the cluster and public network
    interface::mtu { [ $cluster_iface, $public_iface ]:
        mtu    => 9000,
        before => Class['ceph::common'],
    }

    # Each ceph osd server runs multiple daemons, each daemon listens on 6 ports
    # The ports can range anywhere between 6800 and 7100. This can be controlled
    # with the `ms bind port min` and `ms bind port max` ceph config parameters.

    $firewall_osd_access = $osd_hosts.map | $key, $value | { $value['cluster']['addr'] }
    firewall::service { 'ceph_osd_cluster_range':
        proto      => 'tcp',
        port_range => [6800, 7100],
        srange     => $firewall_osd_access,
        drange     => [$host_conf['cluster']['addr']],
        qos        => 'low',
        before     => Class['ceph::common'],
    }

    # Set DSCP for heartbeat traffic to high priority
    ferm::rule { 'osd_heartbeat_qos_high':
        table => 'mangle',
        chain => 'POSTROUTING',
        prio  => '05',
        rule  => 'proto tcp sport 6800:7100 mod dscp dscp 0x30 DSCP set-dscp-class AF21;',
    }

    # Return from POSTROUTING chain so further rules are not processed for heartbeat traffic
    ferm::rule { 'osd_heartbeat_qos_high_return':
        table => 'mangle',
        chain => 'POSTROUTING',
        prio  => '06',
        rule  => 'proto tcp sport 6800:7100 mod dscp dscp-class AF21 RETURN;',
    }

    # Set a static route with the gateway to the rest of the osds networks
    # We are assuming /24 for each network, and .254 to be the GW
    $cluster_networks.each | Stdlib::IP::Address $cluster_network_with_nm | {
        $cluster_network = split($cluster_network_with_nm, '[/]')[0]
        $cur_ip_chunks = split($host_conf['cluster']['addr'], '[.]')
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
                interface => $cluster_iface,
                persist   => true,
                require   => Interface::Ip['osd-cluster-ip'],
            }
        }
    }

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

    $mon_addrs = $mon_hosts.map | $key, $value | { $value['public']['addr'] }
    $osd_public_addrs = $osd_hosts.map | $key, $value | { $value['public']['addr'] }
    firewall::service { 'ceph_osd_range':
        proto      => 'tcp',
        port_range => [6800, 7100],
        srange     => $mon_addrs + $osd_public_addrs + $client_networks + $cinder_backup_nodes,
        drange     => [$host_conf['public']['addr']],
        before     => Class['ceph::common'],
    }

    class { 'ceph::common':
        home_dir                  => $data_dir,
        ceph_repository_component => $ceph_repository_component,
    }

    class { 'ceph::config':
        cluster_networks        => $cluster_networks,
        enable_libvirt_rbd      => false,
        enable_v2_messenger     => true,
        fsid                    => $fsid,
        mon_hosts               => $mon_hosts,
        osd_hosts               => $osd_hosts,
        public_networks         => $public_networks,
        with_location_hook      => $with_location_hook,
        enable_qos              => $enable_qos,
        osd_enable_discard      => $osd_enable_discard,
        slow_ops_threshold      => $slow_ops_threshold,
        slow_ops_window_seconds => $slow_ops_window_seconds,
    }

    $mon_host_ips = $mon_hosts.reduce({}) | $memo, $value | {
        $memo + {$value[0] => $value[1]['public']['addr'] }
    }
    $osd_public_host_ips = $osd_hosts.reduce({}) | $memo, $value | {
        $memo + {$value[0] => $value[1]['public']['addr'] }
    }
    $osd_cluster_host_ips = $osd_hosts.reduce({}) | $memo, $value | {
        $memo + {$value[0] => $value[1]['cluster']['addr'] }
    }
    # This adds latency stats between from this osd to the rest of the ceph fleet
    class { 'prometheus::node_pinger':
        nodes_to_ping_regular_mtu => $mon_host_ips,
        nodes_to_ping_jumbo_mtu   => $osd_public_host_ips + $osd_cluster_host_ips,
    }

    # Get the $num_os_disks with less space, as those are **expected** to be the os drives
    $facts['disks'].map |String $device_name, Hash $device_info| {
        [$device_info['size_bytes'], $device_name, $device_info]
    }.sort[$num_os_disks, -1].each |Tuple[Integer,String,Hash] $device_tuple| {
        $device_name=$device_tuple[1]
        $device_info=$device_tuple[2]
        if ('model' in $device_info and $device_info['model'] in $disk_models_without_write_cache) {
            exec { "Disable write cache on device /dev/${device_name}":
                # 0->disable, 1->enable
                command => "hdparm -W 0 /dev/${device_name}",
                user    => 'root',
                unless  => "hdparm -W /dev/${device_name} | grep write-caching | grep -q off",
                path    => ['/usr/sbin', '/usr/bin'],
            }
        }

        exec { "Set IO scheduler on device /dev/${device_name} to ${disks_io_scheduler}":
            command => "echo ${disks_io_scheduler} > /sys/block/${device_name}/queue/scheduler",
            user    => 'root',
            unless  => "grep -q '\\[${disks_io_scheduler}\\]' /sys/block/${device_name}/queue/scheduler",
            path    => ['/usr/sbin', '/usr/bin'],
        }
    }

    # Using netbox to know where we are situated in the datacenter
    require profile::netbox::host
    $location = $profile::netbox::host::location
    unless $location {
        warning("${facts['networking']['fqdn']}: no Netbox location found")
    } else {
        # see https://docs.ceph.com/en/latest/rados/operations/crush-map/#custom-location-hooks
        file {'/usr/bin/custom-crush-location-hook':
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            content => @(EOS/L)
                #!/bin/sh
                echo "host=$(hostname -s) rack=$(cat /etc/rack) root=default"
            | EOS
        }
        file {'/etc/rack':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => $location['rack'],
        }
    }
}
