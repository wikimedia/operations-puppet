class openstack::swift::storage-node (
  $swift_zone,
  $ring_server,
  $swift_hash_suffix    = 'swift_secret',
  $swift_local_net_ip   = $::ipaddress_eth0,
  $storage_type         = 'loopback',
  $storage_base_dir     = '/srv/loopback-device',
  $storage_mnt_base_dir = '/srv/node',
  $storage_devices      = ['1', '2'],
  $storage_weight       = 1,
  $package_ensure       = 'present',
  $byte_size            = '1024',
) {

  if !defined(swift){
    class { 'swift':
      swift_hash_suffix => $swift_hash_suffix,
      package_ensure    => $package_ensure,
    }
  }

  case $storage_type {
    'loopback': {
      # create xfs partitions on a loopback device and mount them
      swift::storage::loopback { $storage_devices:
        base_dir     => $storage_base_dir,
        mnt_base_dir => $storage_mnt_base_dir,
        require      => Class['swift'],
      }
    }
    # make xfs filesystem on physical disk and mount them
    'disk': {
      swift::storage::disk {$storage_devices:
        mnt_base_dir  => $storage_mnt_base_dir,
        byte_size     => $byte_size,
      }
    }
    default: {
    }
  }

  # install all swift storage servers together
  class { 'swift::storage::all':
    storage_local_net_ip => $swift_local_net_ip,
  }

  openstack::swift::device_endpoint { $storage_devices:
    swift_local_net_ip => $swift_local_net_ip,
    zone               => $swift_zone,
    weight             => $storage_weight,
  }

  # rsync rings from the ring server
  swift::ringsync { ['account','container','object']:
    ring_server => $ring_server,
  }
}
