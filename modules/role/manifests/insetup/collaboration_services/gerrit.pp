# SPDX-License-Identifier: Apache-2.0
class role::insetup::collaboration_services::gerrit {
    include profile::base::production
    include profile::firewall
    include profile::firewall::nftables_throttling
    include profile::prometheus::apache_exporter
    include profile::java

}
