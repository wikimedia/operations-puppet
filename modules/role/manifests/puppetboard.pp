# Class: role::puppetboard
#
# This role installs all the Puppetboard related parts as WMF requires it
#
# Actions:
#       Deploy Puppetboard
#
# Sample Usage:
#       role(puppetboard)
#

class role::puppetboard {
    system::role { 'puppetboard': description => 'Puppetboard server' }

    include ::profile::base::firewall
    include ::profile::standard
    include ::profile::puppetboard
}
