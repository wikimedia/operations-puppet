# SPDX-License-Identifier: Apache-2.0
# = Class: role::cirrus::opensearch
#
# This class sets up OpenSearch specifically for CirrusSearch.
#
class role::cirrus::opensearch {
    include profile::base::production
    include profile::firewall
    include profile::lvs::realserver
    include profile::lvs::realserver::ipip
    include profile::opensearch::cirrus::server
}
