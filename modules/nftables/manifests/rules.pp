# SPDX-License-Identifier: Apache-2.0
# @summary Adds custom nftables rules as needed, useful for more complex matching for QoS
# @param ensure Ensure of the resource
# @param prio The rules are included with a path prefix, by default all rules use 10,
#             but if ordering matters for a given rule it can be lower or higher.
# @param desc An optional description which gets added as a comment to the .nft file
# @param chain The chain - prerouting/input/output/postrouting - to add the rules to
# @param rules Array of strings, each being an nftables rule to add to the given chain
define nftables::rules (
    Wmflib::Ensure   $ensure = present,
    Optional[String] $desc   = undef,
    Integer[0,99]    $prio   = 10,
    Nftables::Chain  $chain  = undef,
    Array[String]    $rules  = undef,
) {

    $content = @("CONTENT")
    # Managed by puppet
    # ${desc}
    ${rules.join("\n")}
    | CONTENT

    $filename = sprintf('/etc/nftables/%s/%02d_%s_rules.nft', $chain, $prio, $title)
    @file { $filename:
        ensure  => $ensure,
        mode    => '0444',
        content => $content,
        notify  => Service['nftables'],
        tag     => 'nft',
    }
}
