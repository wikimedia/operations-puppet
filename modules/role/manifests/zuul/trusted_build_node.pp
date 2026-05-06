# SPDX-License-Identifier: Apache-2.0
# new zuul - trusted build node (T393873)
class role::zuul::trusted_build_node {
    include profile::base::production
    include profile::firewall
    include profile::zuul::trusted_build_node
}
