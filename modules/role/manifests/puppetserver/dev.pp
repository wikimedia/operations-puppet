# SPDX-License-Identifier: Apache-2.0
class role::puppetserver::dev {
    system::role { 'puppetserver::dev':
        description => 'Dev env puppet server',
    }

    include profile::base::production
    include profile::firewall
    include profile::puppetserver
}
