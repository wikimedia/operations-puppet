# SPDX-License-Identifier: Apache-2.0
class role::debmonitor::server_dev {
    include profile::firewall
    include profile::base::production
    include profile::tlsproxy::envoy
    include profile::debmonitor::server
    include profile::debmonitor::localdb
}
