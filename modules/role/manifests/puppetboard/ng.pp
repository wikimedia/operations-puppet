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

class role::puppetboard::ng {
    system::role { 'puppetboard': description => 'Puppetboard server' }

    include profile::base::production
    include profile::base::firewall
    include profile::puppetboard::ng
    include profile::tlsproxy::envoy # TLS termination
}
