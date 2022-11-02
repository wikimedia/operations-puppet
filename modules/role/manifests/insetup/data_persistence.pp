# SPDX-License-Identifier: Apache-2.0
class role::insetup::data_persistence {
    system::role { 'insetup::data_persistence':
        ensure      => 'present',
        description => 'Host being setup by Data Persistence SREs',
    }

    include profile::base::production
    include profile::base::firewall
}
