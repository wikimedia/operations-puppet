# Class: role::debmonitor::server
#
# This role installs all the Debmonitor server related parts as WMF requires it
#
# Actions:
#       Deploy Debmonitor server
#
# Sample Usage:
#       role(debmonitor::server)
#

class role::debmonitor::server {
    include profile::firewall
    include profile::base::production
    include profile::tlsproxy::envoy
    include profile::debmonitor::server
}
