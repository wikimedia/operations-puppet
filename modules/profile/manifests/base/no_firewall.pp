# SPDX-License-Identifier: Apache-2.0
# This is a stub profile which designates that a given role is _not_ meant to
# have profile::base::firewall applied. This is e.g. the case for some OpenStack
# roles who manage iptables rule on their own
class profile::base::no_firewall () {
}
