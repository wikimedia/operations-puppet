# SPDX-License-Identifier: Apache-2.0
# @summary a shim define to support a common interface between ferm::client and nft::client
# @param proto the protocol to use
# @param port the port to configure
# @param ensure the ensurable parameter
# @param desc a description to add as a comment
# @param prio the priority
# @param drange the destination range to configure
# @param notrack set the rule with no state tracking
define firewall::client(
    $proto,
    $port,
    $ensure  = present,
    $desc    = '',
    $prio    = '10',
    $drange  = undef,
    $notrack = false,
) {
    include firewall
    case $firewall::provider {
        'none': {}
        'ferm': {
            ferm::client { $title:
                * => wmflib::resource::dump_params(),
            }
        }
        default: { fail('invalid provider') }
    }
}
