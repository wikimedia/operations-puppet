# SPDX-License-Identifier: Apache-2.0
# @summary a shim define to support a common interface between ferm::client and nft::client
# @param proto the protocol to use
# @param port the port to configure
# @param ensure the ensurable parameter
# @param desc a description to add as a comment
# @param prio the priority
# @param drange the destination range to configure
# @param notrack set the rule with no state tracking
# @param skip_output_chain can be used to avoid adding uneeded rule if we only want to set qos
# @param qos traffic class (mgmt/high/low) to control DSCP marking
define firewall::client(
    $proto,
    $port,
    $ensure            = present,
    $desc              = '',
    $prio              = 10,
    $drange            = undef,
    $notrack           = false,
    $skip_output_chain = false,
    $qos               = '',
) {
    if $drange =~ String {
        fail('The drange needs to be passed as an array of hosts or IPs')
    }

    if $port =~ Pattern[/\d{1,5}:\d{1,5}/] {
        fail('The port needs to be converted to use a port_range')
    }

    if $port =~ String {
        fail('The port needs to be converted to an array; use a port or port_range')
    }

    # Declare resources for both providers. Both types use virtual resources
    # so they will not have any effect if that firewall provider is not in
    # use on that host.
    # This approach works on hosts with a firewall, instances with P:firewall
    # with type => none applied, and on hosts without P:firewall at all.

    ferm::client { $title:
        * => wmflib::resource::dump_params(),
    }

    nftables::client { $title:
        *       => wmflib::resource::filter_params('drange'),
        dst_ips => $drange.then |$range| { wmflib::hosts2ips($range) },
    }
}
