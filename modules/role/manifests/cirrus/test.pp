# SPDX-License-Identifier: Apache-2.0
# role to (ironically) apply on unpuppetized systems
#
class role::cirrus::test {
    include profile::base::production
    include profile::firewall
    include profile::opensearch::cirrus::test
}
