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
    system::role { 'debmonitor::server': description => 'DebMonitor server' }

    include ::profile::base::firewall
    include ::standard
    include ::profile::debmonitor::server
}
