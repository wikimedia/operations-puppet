# SPDX-License-Identifier: Apache-2.0
class role::ncmonitor {

    system::role { 'ncmonitor':
        description => 'Automated syncing of registered MarkMonitor DNS and downstream services'
    }

    include profile::base::production
    include profile::firewall
    include profile::ncmonitor

}
