# SPDX-License-Identifier: Apache-2.0
# temp allow rsyncing phabricator data to new servers
class role::phabricator::migration {

    system::role {'phabricator::migration':
        description => 'temp role to allow migrating Phabricator data to a new server',
    }

    class { 'scap::user': }

    include ::profile::base::production
    include ::profile::firewall
    # include ::profile::phabricator::migration
}
