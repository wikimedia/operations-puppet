# SPDX-License-Identifier: Apache-2.0
# @summary Appends a /32 or /128 (depending on the address family) CIDR suffix
#  to an IP address, if the parameter is not already in CIDR format
function wmflib::ip2cidr (
  Stdlib::IP::Address $ip,
) >> Wmflib::IP::Address::CIDR {
  $ip ? {
    Stdlib::IP::Address::V4::Nosubnet => "${ip}/32",
    Stdlib::IP::Address::V6::Nosubnet => "${ip}/128",
    default                           => $ip,
  }
}
