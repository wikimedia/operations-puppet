# SPDX-License-Identifier: Apache-2.0
# @summary Either an IP address or a CIDR prefix length to use as a netmask
type Network::Netmask = Variant[
  Integer[0, 128],
  Stdlib::IP::Address::Nosubnet,
]
