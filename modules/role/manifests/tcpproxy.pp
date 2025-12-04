# SPDX-License-Identifier: Apache-2.0
# sets up a generic TCP proxy
class role::tcpproxy {
    include profile::base::production
    include profile::firewall
    include profile::tcpproxy
    include profile::lvs::realserver
    include profile::lvs::realserver::ipip
    include profile::conftool::client
}
