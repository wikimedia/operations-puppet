# Class: role::netbox
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
    include ::profile::netbox::httpd
    include ::profile::prometheus::postgres_exporter
}
