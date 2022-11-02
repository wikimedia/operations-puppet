# SPDX-License-Identifier: Apache-2.0
class role::insetup::traffic {
    system::role { 'insetup::traffic':
        ensure      => 'present',
        description => 'Host being setup by Traffic SREs',
    }

    include profile::base::production
    include profile::base::firewall
}
