# SPDX-License-Identifier: Apache-2.0
# Exists to contain the resource-like include below (an include-like include
# would violate style in the profile namespace), allowing two other dns
# profiles to include this one...
class profile::dns::check_dns_query {
    class { '::nagios_common::check_dns_query': }
}
