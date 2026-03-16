# SPDX-License-Identifier: Apache-2.0
class role::kafka::monitoring {
    include profile::base::production
    include profile::firewall
    include profile::kafka::monitoring
}
