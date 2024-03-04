# SPDX-License-Identifier: Apache-2.0
# @summary cloud vps per-project puppetserver
class role::puppetserver::cloud_vps_project {
    system::role { 'puppetserver::cloud_vps_project':
        description => 'Cloud VPS per-project Puppet server',
    }

    include profile::puppetserver::wmcs
    include profile::puppetserver::scripts
}
