# SPDX-License-Identifier: Apache-2.0
# Returns the addresses of our namservers (v4 and v6) from authdns_addrs in
# hieradata/common.yaml.
function wmflib::get_authdns_addrs() >> Array[Stdlib::IP::Address::Nosubnet] {
  $authdns_addrs = lookup('authdns_addrs')
  $authdns_addrs.map |$authdns, $value| {
    $value['address']
  }
}
