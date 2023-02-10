# SPDX-License-Identifier: Apache-2.0

class role::idm_test {
    system::role {'idm_test':
        description => 'Wikimedia identity management portal (staging)',
    }

    include profile::base::production
    include profile::base::firewall
    include profile::idm
}
