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
    include profile::base::production
    include profile::firewall
    include profile::puppetboard
    include profile::tlsproxy::envoy # TLS termination
}
