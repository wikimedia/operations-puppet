#
# Installs only the OpenStack client libraries
#
# === Parameters
#
# [ceilometer]
#   (optional) Install the Ceilometer client package
#
# [cinder]
#   (optional) Install the Cinder client package
#
# [glance]
#   (optional) Install the Glance client package
#
# [keystone]
#   (optional) Install the Keystone client package
#
# [nova]
#   (optional) Install the Nova client package
#
# [neutron]
#   (optional) Install the Neutron client package
#

class openstack::client (
  $ceilometer = true,
  $cinder = true,
  $glance = true,
  $keystone = true,
  $nova = true,
  $neutron = true
) {

  if $ceilometer {
    include ceilometer::client
  }

  if $cinder {
    include cinder::client
  }

  if $glance {
    include glance::client
  }

  if $keystone {
    include keystone::client
  }

  if $nova {
    include nova::client
  }

  if $neutron {
    include neutron::client
  }
}
