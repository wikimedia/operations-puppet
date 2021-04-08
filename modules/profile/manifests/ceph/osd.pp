# Class: profile::ceph::osd
#
# This profile configures Ceph object storage hosts with the osd daemon
class profile::ceph::osd(
    Array[Stdlib::Fqdn]  $openstack_controllers = lookup('profile::ceph::openstack_controllers'),
    Hash[String,Hash]    $mon_hosts         = lookup('profile::ceph::mon::hosts'),
    Hash[String,Hash]    $osd_hosts         = lookup('profile::ceph::osd::hosts'),
    Stdlib::AbsolutePath $admin_keyring     = lookup('profile::ceph::admin_keyring'),
    Stdlib::IP::Address  $cluster_network   = lookup('profile::ceph::cluster_network'),
    Stdlib::IP::Address  $public_network    = lookup('profile::ceph::public_network'),
    Stdlib::Unixpath     $data_dir          = lookup('profile::ceph::data_dir'),
    String               $admin_keydata     = lookup('profile::ceph::admin_keydata'),
    String               $fsid              = lookup('profile::ceph::fsid'),
    Stdlib::AbsolutePath $bootstrap_keyring = lookup('profile::ceph::osd::bootstrap_keyring'),
    String               $bootstrap_keydata = lookup('profile::ceph::osd::bootstrap_keydata'),
    Array[String]        $disk_models_without_write_cache = lookup('profile::ceph::osd::disk_models_without_write_cache'),
    Array[String]        $os_disks = lookup('profile::ceph::osd::os_disks'),
    String               $disks_io_scheduler = lookup('profile::ceph::osd::disks_io_scheduler', { default_value => 'mq-deadline'}),
    String               $ceph_repository_component  = lookup('profile::ceph::ceph_repository_component',  { 'default_value' => 'thirdparty/ceph-nautilus-buster' })
) {
    # Ceph OSDs should use the performance governor, not the default 'powersave'
    # governor
    class { 'cpufrequtils': }

    include network::constants
    # Limit the client connections to the hypervisors in eqiad and codfw
    $client_networks = [
        $network::constants::all_network_subnets['production']['eqiad']['private']['labs-hosts1-b-eqiad']['ipv4'],
        $network::constants::all_network_subnets['production']['codfw']['private']['labs-hosts1-b-codfw']['ipv4'],
    ]

    # Each ceph osd server runs multiple daemons, each daemon listens on 6 ports
    # The ports can range anywhere between 6800 and 7100. This can be controlled
    # with the `ms bind port min` and `ms bind port max` ceph config parameters.

    # The cluster interface is used for OSD data replication and heartbeat network traffic
    interface::manual{ 'osd-cluster':
        interface => $osd_hosts["$::fqdn"]['cluster']['iface'],
    }
    interface::ip { 'osd-cluster-ip':
        interface => $osd_hosts["$::fqdn"]['cluster']['iface'],
        address   => $osd_hosts["$::fqdn"]['cluster']['addr'],
        prefixlen => $osd_hosts["$::fqdn"]['cluster']['prefix'],
        require   => Interface::Manual['osd-cluster'],
        before    => Class['ceph::common'],
    }

    # Tune the MTU on both the cluster and public network
    interface::setting { 'osd-cluster-mtu':
        interface => $osd_hosts["$::fqdn"]['cluster']['iface'],
        setting   => 'mtu',
        value     => '9000',
        before    => Class['ceph::common'],
        notify    => Exec['set-osd-cluster-mtu'],
    }
    interface::setting { 'osd-public-mtu':
        interface => $osd_hosts["$::fqdn"]['public']['iface'],
        setting   => 'mtu',
        value     => '9000',
        before    => Class['ceph::common'],
        notify    => Exec['set-osd-public-mtu'],
    }
    # Make sure the interface is in sync with configuration changes
    exec { 'set-osd-cluster-mtu':
        command     => "/usr/sbin/ip link set mtu 9000 ${osd_hosts[$facts['fqdn']]['cluster']['iface']}",
        refreshonly => true,
    }
    exec { 'set-osd-public-mtu':
        command     => "/usr/sbin/ip link set mtu 9000 ${osd_hosts[$facts['fqdn']]['public']['iface']}",
        refreshonly => true,
    }

    $ferm_cluster_srange = join($osd_hosts.map | $key, $value | { $value['cluster']['addr'] }, ' ')
    ferm::service { 'ceph_osd_cluster_range':
        proto  => 'tcp',
        port   => '6800:7100',
        srange => "(${ferm_cluster_srange})",
        drange => $osd_hosts["$::fqdn"]['cluster']['addr'],
        before => Class['ceph::common'],
    }

    # The public network is used for communication between Ceph serivces and client traffic
    $mon_addrs = $mon_hosts.map | $key, $value | { $value['public']['addr'] }
    $osd_addrs = $osd_hosts.map | $key, $value | { $value['public']['addr'] }
    $openstack_controller_ips = $openstack_controllers.map |$host| { ipresolve($host, 4) }
    $ferm_public_srange = join(concat($mon_addrs, $osd_addrs, $client_networks, $openstack_controller_ips), ' ')
    ferm::service { 'ceph_osd_range':
        proto  => 'tcp',
        port   => '6800:7100',
        srange => "(${ferm_public_srange})",
        drange => $osd_hosts["$::fqdn"]['public']['addr'],
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

    class { 'ceph::admin':
        admin_keyring => $admin_keyring,
        admin_keydata => $admin_keydata,
        data_dir      => $data_dir,
    }

    # We need this to finish initial osd setup
    ceph::keyring { 'client.bootstrap-osd':
        keyring => $bootstrap_keyring,
        keydata => $bootstrap_keydata,
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
