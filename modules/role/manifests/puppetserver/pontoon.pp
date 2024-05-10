# SPDX-License-Identifier: Apache-2.0
# = Class: role::puppetserver::pontoon
#
# Sets up a Pontoon puppetserver. Meant to work in Cloud VPS only.
# See also https://wikitech.wikimedia.org/wiki/Puppet/Pontoon
#
class role::puppetserver::pontoon {
    system::role { 'puppetserver::pontoon':
        description => 'Pontoon per-stack puppetserver',
    }

    # profile::base is needed here for bootstraps to happen, ideally
    # profile::base::production is used instead
    include profile::base
    include profile::firewall

    include profile::puppetserver::pontoon
    include profile::puppetserver::scripts
}
