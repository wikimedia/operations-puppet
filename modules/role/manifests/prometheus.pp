# SPDX-License-Identifier: Apache-2.0
class role::prometheus {
    include profile::base::production
    include profile::firewall

    include profile::lvs::realserver

    include profile::prometheus::common

    include profile::prometheus::instances

    include profile::prometheus::pushgateway

    include profile::alerts::deploy::prometheus

    include profile::prometheus::rsyncd
    include profile::prometheus::web

    include profile::prometheus::web_idp
}
