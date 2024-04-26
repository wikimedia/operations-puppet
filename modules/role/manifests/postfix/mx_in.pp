# SPDX-License-Identifier: Apache-2.0
class role::postfix::mx_in {
    include profile::base::production
    include profile::firewall
    include profile::postfix::mx
    # vrts aliases
    include profile::mail::vrts
}
