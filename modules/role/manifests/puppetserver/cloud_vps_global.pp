# SPDX-License-Identifier: Apache-2.0
# @summary cloud vps global puppetserver
class role::puppetserver::cloud_vps_global {
    system::role { 'puppetserver::cloud_vps_global':
        description => 'Cloud VPS global Puppet server',
    }

    include profile::puppetserver::wmcs
    include profile::puppetserver::scripts
}
