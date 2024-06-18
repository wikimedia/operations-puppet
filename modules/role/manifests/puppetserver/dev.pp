# SPDX-License-Identifier: Apache-2.0
class role::puppetserver::dev {
    include profile::base::production
    include profile::firewall
    include profile::puppetserver
}
