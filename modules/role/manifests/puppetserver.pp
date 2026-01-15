# SPDX-License-Identifier: Apache-2.0
# @summary puppetserver rol
class role::puppetserver {
    include profile::base::production
    include profile::firewall
    include profile::puppetserver::backup
    # puppetserver
    include profile::puppetserver
    include profile::puppetserver::git::private
    include profile::puppetserver::scripts
    include profile::puppetserver::volatile
    include profile::puppetserver::configmaster
    # conftool
    include profile::conftool::master
    include profile::conftool::requestctl_client
    require profile::conftool::state
    require profile::conftool::conftool2git
}
