# SPDX-License-Identifier: Apache-2.0

class role::idm {
    system::role {'idm':
        description => 'Wikimedia identity management portal',
    }

    include profile::base::production
    include profile::firewall
    include profile::idm
}
