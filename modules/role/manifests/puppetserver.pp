# SPDX-License-Identifier: Apache-2.0
# @summary puppetserver rol
class role::puppetserver {
    system::role { 'puppetserver':
        description => 'Puppetserver',
    }

    include profile::base::production
    include profile::firewall
    include profile::puppetserver::backup
    # puppetserver
    include profile::puppetserver
    include profile::puppetserver::git::private
    include profile::puppetserver::scripts
    include profile::puppetserver::volatile
    # conftool
    include profile::conftool::master
    include profile::conftool::requestctl_client
    require profile::conftool::state
}
