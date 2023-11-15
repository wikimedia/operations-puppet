# SPDX-License-Identifier: Apache-2.0
function wmflib::ip_family(Stdlib::IP::Address $ip) {
  $ip ? {
    Stdlib::IP::Address::V4 => 4,
    Stdlib::IP::Address::V6 => 6,
    default => fail('unrecognized ip'),
  }
}
