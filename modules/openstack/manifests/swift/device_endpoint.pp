#
# Exports endpoints for all swift devices
#
define openstack::swift::device_endpoint ($swift_local_net_ip, $zone, $weight) {
  @@ring_object_device { "${swift_local_net_ip}:6000/${name}":
    zone   => $zone,
    weight => $weight,
  }
  @@ring_container_device { "${swift_local_net_ip}:6001/${name}":
    zone   => $zone,
    weight => $weight,
  }
  @@ring_account_device { "${swift_local_net_ip}:6002/${name}":
    zone   => $zone,
    weight => $weight,
  }
}
