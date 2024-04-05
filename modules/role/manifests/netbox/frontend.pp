# Class: role::netbox::frontend
#
# This role installs all the Netbox web frontend related parts as WMF requires it
#
# Actions:
#       Deploy Netbox web frontend
#
# Requires:
#
# Sample Usage:
#       role(netbox::frontend)
#

class role::netbox::frontend {
    include profile::base::production
    include profile::netbox
    include profile::netbox::automation
    include profile::netbox::scripts
    include profile::firewall
    # Fixme consider adding this later
    # include ::profile::backup::host

}
