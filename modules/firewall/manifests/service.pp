# SPDX-License-Identifier: Apache-2.0
# @summary a shim define to support a common interface between ferm::service and nft::service
# @param proto the protocol to use
# @param port a single port or an array of ports to configure
# @param ensure the ensurable parameter
# @param desc a description to add as a comment
# @param prio the priority
# @param srange the source range to configure
# @param drange the destination range to configure
# @param src_sets An optional array of predefined sets of hosts FROM which incoming traffic is allowed (defined in profile::firewall::nftables_base_sets).
# @param dst_sets An optional array of predefined sets of hosts TO which incoming traffic is allowed (defined in profile::firewall::nftables_base_sets).
# @param notrack set the rule with no state tracking
# @param qos specify a traffic class for DSCP marking (low/normal/high/control)
define firewall::service(
    Wmflib::Protocol              $proto,
                                  $port   = undef,
    Wmflib::Ensure                $ensure = present,
    Optional[String]              $desc = '',
    Integer[0,99]                 $prio = 10,
    Optional[Firewall::Portrange] $port_range = undef,
                                  $srange = undef,
                                  $drange = undef,
    Optional[Array[String[1]]]    $src_sets = undef,
    Optional[Array[String[1]]]    $dst_sets = undef,
    Boolean                       $notrack = false,
    Optional[Firewall::Qos]       $qos               = undef,
) {
    include firewall

    $escaped_title = regsubst($title, '\W', '_', 'G')

    case $firewall::provider {
        'none': {}
        'ferm': {
            ferm::service { $escaped_title:
                * => wmflib::resource::dump_params(),
            }
        }
        'nftables': {

            if $srange =~ String {
                fail('The srange needs to be passed as an array of hosts or IPs')
            }

            if $drange =~ String {
                fail('The drange needs to be passed as an array of hosts or IPs')
            }

            if $port =~ Pattern[/\d{1,5}:\d{1,5}/] {
                fail('The port needs to be converted to use a port_range')
            }

            if $port =~ String {
                fail('The port needs to be converted to an array; use a port or port_range')
            }

            nftables::service { $title:
                *       => wmflib::resource::filter_params('drange', 'srange'),
                src_ips => $srange.then |$range| { wmflib::hosts2ips($range) },
                dst_ips => $drange.then |$range| { wmflib::hosts2ips($range) },
            }
        }

        default: { fail('invalid provider') }
    }
}
