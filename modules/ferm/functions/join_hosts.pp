# SPDX-License-Identifier: Apache-2.0
# @summary merges a list of IP addresses and hosts to a format Ferm understands
function ferm::join_hosts (
  Wmflib::Firewall::Hosts $input,
) >> String {
  if $input =~ String {
    $input
  } else {
    $parts = $input.map |$input| {
      $input ? {
        Stdlib::IP::Address => $input,
        Ferm::Variable      => $input,
        default             => dnsquery::lookup($input, true)
      }
    }.flatten.sort.join(' ')

    "(${parts})"
  }
}
