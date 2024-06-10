# SPDX-License-Identifier: Apache-2.0

# @type Wmflib::IP::Address::CIDR
#
# A type for IP address and subnet, allowing V4 or V6.
# This will made obsolete by Stdlib::IP::Address::CIDR
# in puppet-stdlib v9, and can be replaced by it then.

type Wmflib::IP::Address::CIDR = Variant [
    Stdlib::IP::Address::V4::CIDR,
    Stdlib::IP::Address::V6::CIDR,
]
