# Class: role::netbox::frontend
#
# This role installs all the Netbox related parts as WMF requires it
#
# Actions:
#       Deploy Netbox
#
# Requires:
#
# Sample Usage:
#       role(netbox)
#

class role::netbox {
    system::role { 'netbox': description => 'Netbox server' }

    include ::profile::netbox
    include ::profile::netbox::postgres
    include ::profile::prometheus::postgres_exporter
    include ::profile::base::firewall
}
