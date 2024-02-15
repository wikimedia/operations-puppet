# SPDX-License-Identifier: Apache-2.0
# Role for Ganeti in routed setup T300152
class role::ganeti_routed {
    include profile::base::production
    include profile::ganeti
    include profile::firewall
}
