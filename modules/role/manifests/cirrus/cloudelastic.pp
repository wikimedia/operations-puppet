# SPDX-License-Identifier: Apache-2.0
# = Class: role::cirrus::cloudelastic
#
# This class sets up OpenSearch for cloudelastic
#
class role::cirrus::cloudelastic {
    include profile::base::production
    include profile::firewall
    include profile::lvs::realserver
    include profile::lvs::realserver::ipip
    include profile::opensearch::cirrus::server
}
