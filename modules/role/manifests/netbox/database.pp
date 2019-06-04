# Class: role::netbox::database
#
# This role installs all the Netbox database related parts as WMF requires it
#
# Actions:
#       Deploy Netbox database server
#
# Requires:
#
# Sample Usage:
#       role(netbox::database)
#

class role::netbox::database {
    system::role { 'netbox::database': description => 'Netbox database server' }

    include ::profile::netbox::postgres
    include ::profile::prometheus::postgres_exporter
}
