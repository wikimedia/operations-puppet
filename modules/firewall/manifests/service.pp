# SPDX-License-Identifier: Apache-2.0
# @summary a shim define to support a common interface between ferm::service and nft::service
# @param proto the protocol to use
# @param port the port to configure
# @param ensure the ensurable parameter
# @param desc a description to add as a comment
# @param prio the priority
# @param srange the source range to configure
# @param drange the destination range to configure
# @param notrack set the rule with no state tracking
define firewall::service(
    $proto,
    $port,
    $ensure  = present,
    $desc    = '',
    $prio    = 10,
    $srange  = undef,
    $drange  = undef,
    $notrack = false,
) {
    include firewall
    case $firewall::provider {
        'ferm': {
            ferm::service { $title:
                * => wmflib::dump_params(),
            }
        }
        default: { fail('invalid provider') }
    }
}
