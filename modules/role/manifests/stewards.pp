# SPDX-License-Identifier: Apache-2.0
# special VM for stewards (T344164)
class role::stewards {
    include profile::base::production
    include profile::firewall
    include profile::stewards
}
