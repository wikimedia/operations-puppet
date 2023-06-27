# SPDX-License-Identifier: Apache-2.0
# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class role::puppetserver {
    system::role { 'puppetserver':
        description => 'Puppetserver'
    }

    include profile::base::production
    include profile::firewall
    include profile::puppetserver
    include profile::puppetserver::git::private
    include profile::puppetserver::scripts
}
