# Class: role::netbox::standalone
#
# This role installs all the Netbox web frontend related parts and database.
#
# Actions:
#       Deploy Netbox web frontend
#       Deploy Netbox database
#
# Requires:
#
# Sample Usage:
#       role(netbox::standalone)
#

class role::netbox::standalone {
    include profile::base::production
    include profile::netbox
    include profile::netbox::db
    include profile::prometheus::postgres_exporter
    include profile::firewall
}
