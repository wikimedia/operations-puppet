# SPDX-License-Identifier: Apache-2.0
function nftables::ip_stmt(
    Variant[Integer[4,4], Integer[6,6]]  $ver,
    Optional[Array[Stdlib::IP::Address]] $src_ips,
    Optional[Array[Stdlib::IP::Address]] $dst_ips,
    Optional[Array[String[1]]]           $src_sets,
    Optional[Array[String[1]]]           $dst_sets,
) >> Array[Array[String[1]]] {
    $type_ver = $ver ? {
        4 => Stdlib::IP::Address::V4,
        6 => Stdlib::IP::Address::V6,
    }
    $ip_ver = $ver ? {
        4 => 'ip',
        6 => 'ip6',
    }
    $src_stmts = nftables::ip_addr_stmt($ver, 'saddr', $src_ips, $src_sets)
    $dst_stmts = nftables::ip_addr_stmt($ver, 'daddr', $dst_ips, $dst_sets)

    if $src_stmts == undef or $dst_stmts == undef {
        $l3_stmts = []
    } elsif $src_stmts == [] and $dst_stmts == [] {
        $l3_stmts = []
    } elsif $src_stmts == [] {
        $l3_stmts = $dst_stmts.map |$dst_stmt| {[$dst_stmt]}
    } elsif $dst_stmts == [] {
        $l3_stmts = $src_stmts.map |$src_stmt| {[$src_stmt]}
    } else {
        $l3_stmts = $src_stmts.reduce([]) |$memo, $src_stmt| {
            $dst_stmts.reduce($memo) |$memo2, $dst_stmt| {
                $memo2 + [[$src_stmt, $dst_stmt]]
            }
        }
    }
    $l3_stmts
}
