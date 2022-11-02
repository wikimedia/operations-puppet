# SPDX-License-Identifier: Apache-2.0
class role::insetup::observability {
    system::role { 'insetup::observability':
        ensure      => 'present',
        description => 'Host being setup by Observability SREs',
    }

    include profile::base::production
    include profile::base::firewall
}
