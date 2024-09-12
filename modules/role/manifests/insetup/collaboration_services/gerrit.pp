# SPDX-License-Identifier: Apache-2.0
class role::insetup::collaboration_services::gerrit {
    include profile::base::production
    include profile::backup::host
    include profile::firewall
    include profile::firewall::nftables_throttling
    include profile::gerrit::migration
    include profile::gerrit::proxy
    include profile::prometheus::apache_exporter
    include profile::prometheus::nft_throttling_denylist
    include profile::java

}
