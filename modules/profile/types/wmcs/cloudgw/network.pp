# SPDX-License-Identifier: Apache-2.0
# @summary configuration for an individual virtual network for tenants to use
type Profile::Wmcs::Cloudgw::Network = Struct[{
  type     => Enum['default', 'internal', 'floating'],
  networks => Array[Wmflib::IP::Address::CIDR, 1],
}]
