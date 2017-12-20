# Class: profile::netbox
#
# This profile installs all the Netbox related parts as WMF requires it
#
# Actions:
#       Deploy Netbox
#
# Requires:
#
# Sample Usage:
#       include role::netbox
#

class role::netbox {

  system::role { 'netbox': description => 'Netbox server' }

  include ::profile::netbox
  include ::profile::prometheus::postgres_exporter

}
