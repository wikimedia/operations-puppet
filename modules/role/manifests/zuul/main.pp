# SPDX-License-Identifier: Apache-2.0
# new zuul - main server (T393873)
class role::zuul::main {
    include profile::base::production
    include profile::firewall
    include profile::zuul::main
    include profile::zuul::user
}
