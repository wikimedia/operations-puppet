# SPDX-License-Identifier: Apache-2.0
# new zuul - executors (T393873)
class role::zuul::executor {
    include profile::base::production
    include profile::firewall
    include profile::zuul::executor
}
