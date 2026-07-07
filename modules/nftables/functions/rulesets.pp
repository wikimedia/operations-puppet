# SPDX-License-Identifier: Apache-2.0
function nftables::rulesets(
    Enum['input', 'output']              $chain,
    Wmflib::Protocol                     $proto,
    Optional[Nftables::Port]             $port       = undef,
    Optional[Firewall::Portrange]        $port_range = undef,
    Optional[Array[Stdlib::IP::Address]] $src_ips    = undef,
    Optional[Array[Stdlib::IP::Address]] $dst_ips    = undef,
    Optional[Array[String[1]]]           $src_sets   = undef,
    Optional[Array[String[1]]]           $dst_sets   = undef,
    Optional[Firewall::Qos]              $qos        = undef
) {
    # TODO: there is a nftables construct 'concatenation' that can drastically
    # reduce the amount of filtering rules in the system.
    # this define doesn't support it, but we may in the future!
    # see https://wiki.nftables.org/wiki-nftables/index.php/Concatenations

    case $proto {
        'tcp', 'udp': {
            $protocol_match_v4 = nftables::port_stmt($proto, 'dport', $port, $port_range)
            $protocol_match_v6 = $protocol_match_v4
        }
        'vrrp': {
            $protocol_match_v4 = 'ip protocol vrrp'
            $protocol_match_v6 = 'ip6 nexthdr vrrp'
        }
        default: { fail("Unsupported protocol, ${proto}") }
    }

    $l3_v4_stmts = nftables::ip_stmt(
        4,
        $src_ips,
        $dst_ips,
        $src_sets,
        $dst_sets,
    )
    $l3_v6_stmts = nftables::ip_stmt(
        6,
        $src_ips,
        $dst_ips,
        $src_sets,
        $dst_sets,
    )

    $l3_stmts = ($l3_v4_stmts + $l3_v6_stmts)

    # Ensure all ips and sets were not defined before creating a port rule open
    # to all
    if (
        $l3_stmts == []
        and $src_ips == undef
        and $src_sets == undef
        and $dst_ips == undef
        and $dst_sets == undef
    ) {
        # We need to unique() because v4 and v6 rules are identical for UDP or
        # TCP, but not for VRRP.
        $rule_lines = (
            nftables::ip_rules(undef, $protocol_match_v4, [], 'accept') +
            nftables::ip_rules(undef, $protocol_match_v6, [], 'accept')
        ).unique
        $notrack_lines = (
            nftables::ip_rules(undef, $protocol_match_v4, [], 'notrack') +
            nftables::ip_rules(undef, $protocol_match_v6, [], 'notrack')
        ).unique
    } else {
        $rule_lines = nftables::ip_rules($l3_v4_stmts, $protocol_match_v4, [], 'accept') +
            nftables::ip_rules($l3_v6_stmts, $protocol_match_v6, [], 'accept')
        $notrack_lines = nftables::ip_rules($l3_v4_stmts, $protocol_match_v4, [], 'notrack') +
            nftables::ip_rules($l3_v6_stmts, $protocol_match_v6, [], 'notrack')
    }

    if $qos == undef {
        $dscp_rules = []
    } else {
        case $chain {
            'input': {
                # DSCP is set outbound, so we are marking the reply packets to
                # those permitted in the input chain by the rules compiled
                # earlier. In other words we need the same match criteria, but
                # with 'saddr/daddr' reversed etc.
                case $proto {
                    'tcp', 'udp': {
                        $dscp_protocol_match_v4 = nftables::port_stmt($proto, 'sport', $port, $port_range)
                        $dscp_protocol_match_v6 = $dscp_protocol_match_v4
                    }
                    'vrrp': {
                        $dscp_protocol_match_v4  = 'ip protocol vrrp'
                        $dscp_protocol_match_v6  = 'ip6 nexthdr vrrp'
                    }
                    default: { fail("Unsupported protocol, ${proto}") }
                }
                $dscp_l3_v4_stmts = nftables::ip_stmt(
                    4,
                    $dst_ips,
                    $src_ips,
                    $dst_sets,
                    $src_sets,
                )
                $dscp_l3_v6_stmts = nftables::ip_stmt(
                    6,
                    $dst_ips,
                    $src_ips,
                    $dst_sets,
                    $src_sets,
                )
            }
            'output': {
                $dscp_protocol_match_v4 = $protocol_match_v4
                $dscp_protocol_match_v6 = $protocol_match_v6
                $dscp_l3_v4_stmts = $l3_v4_stmts
                $dscp_l3_v6_stmts = $l3_v6_stmts
            }
            default: {
                fail("Unsupported chain ${chain}")
            }
        }

        $dscp_v4_lines = nftables::ip_rules(
            $dscp_l3_v4_stmts,
            $dscp_protocol_match_v4,
            [nftables::dscp_stmt(4, $qos)],
            'return'
        )
        $dscp_v6_lines = nftables::ip_rules(
            $dscp_l3_v6_stmts,
            $dscp_protocol_match_v6,
            [nftables::dscp_stmt(6, $qos)],
            'return'
        )
        $dscp_rules = ($dscp_v4_lines + $dscp_v6_lines).sort
    }

    $rulesets = {
        'base' => $rule_lines,
        'notrack' => $notrack_lines,
        'dscp' => $dscp_rules,
    }

    $rulesets
}
