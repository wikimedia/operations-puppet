# SPDX-License-Identifier: Apache-2.0
class role::postfix::mx_out {
    include profile::base::production
    include profile::firewall
    include profile::postfix::mx
}
