# SPDX-License-Identifier: Apache-2.0
# = Class: role::cirrus::relforge
#
# This class sets up OpenSearch for relevance forge.
#
class role::cirrus::relforge {
    include profile::base::production
    include profile::firewall
    include profile::opensearch::cirrus::relforge
}
