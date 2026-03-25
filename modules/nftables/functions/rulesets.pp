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

    $port_stmt = nftables::port_stmt($proto, 'dport', $port, $port_range)

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
        $rule_lines = nftables::ip_rules(undef, $port_stmt, [], 'accept')
        $notrack_lines = nftables::ip_rules(undef, $port_stmt, [], 'notrack')
    } else {
        $rule_lines = nftables::ip_rules($l3_stmts, $port_stmt, [], 'accept')
        $notrack_lines = nftables::ip_rules($l3_stmts, $port_stmt, [], 'notrack')
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
                $dscp_port_stmt = nftables::port_stmt($proto, 'sport', $port, $port_range)
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
                $dscp_port_stmt = $port_stmt
                $dscp_l3_v4_stmts = $l3_v4_stmts
                $dscp_l3_v6_stmts = $l3_v6_stmts
            }
            default: {
                fail("Unsupported chain ${chain}")
            }
        }

        $dscp_v4_lines = nftables::ip_rules(
            $dscp_l3_v4_stmts,
            $dscp_port_stmt,
            [nftables::dscp_stmt(4, $qos)],
            'return'
        )
        $dscp_v6_lines = nftables::ip_rules(
            $dscp_l3_v6_stmts,
            $dscp_port_stmt,
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
