# SPDX-License-Identifier: Apache-2.0
# @summary role to configer ther serveres that serve config-master.wikimedia.org
class role::config_master {
    include profile::base::production
    include profile::firewall
    include profile::conftool::client
    include profile::discovery::client
    include profile::httpd
    include profile::configmaster
}
