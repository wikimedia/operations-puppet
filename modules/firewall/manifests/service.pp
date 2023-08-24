# SPDX-License-Identifier: Apache-2.0
# @summary a shim define to support a common interface between ferm::service and nft::service
# @param proto the protocol to use
# @param port the port to configure
# @param a port range to configure
# @param ensure the ensurable parameter
# @param desc a description to add as a comment
# @param prio the priority
# @param srange the source range to configure
# @param drange the destination range to configure
# @param notrack set the rule with no state tracking
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
) {
    include firewall
    case $firewall::provider {
        'ferm': {
            ferm::service { $title:
                * => wmflib::resource::dump_params(),
            }
        }
        'nftables': {

            if $srange =~ String {
                fail('The srange needs to needs to passed as an array of hosts or IPs')
            }

            if $drange =~ String {
                fail('The drange needs to needs to passed as an array of hosts or IPs')
            }

            if $port =~ Pattern[/\d{1,5}:\d{1,5}/] {
                fail('The port needs to converted to use a port_range')
            }

            if $port =~ String {
                fail('The port needs to converted to use a port or port_range')
            }

            if $notrack == true {
                fail('Support for notrack not yet added to the nft provider')
            }

            $src_ips = $srange.map |$srange| {
                $srange ? {
                    Stdlib::IP::Address => $srange,
                    default             => dnsquery::lookup($srange, true)
                }
            }.flatten.sort

            $dst_ips = $drange.map |$drange| {
                $drange ? {
                    Stdlib::IP::Address => $drange,
                    default             => dnsquery::lookup($drange, true)
                }
            }.flatten.sort

            nftables::service { $title:
                *       => wmflib::resource::filter_params('drange', 'srange'),
                src_ips => $src_ips,
                dst_ips => $dst_ips,
            }
        }

        default: { fail('invalid provider') }
    }
}
