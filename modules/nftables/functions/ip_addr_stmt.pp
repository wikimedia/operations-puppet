# SPDX-License-Identifier: Apache-2.0
function nftables::ip_addr_stmt(
    Variant[Integer[4,4], Integer[6,6]]  $ver,
    Enum['saddr', 'daddr']               $dir,
    Optional[Array[Stdlib::IP::Address]] $ips,
    Optional[Array[String[1]]]           $sets,
) >> Optional[Array[String[1]]] {
    $type_ver = $ver ? {
        4 => Stdlib::IP::Address::V4,
        6 => Stdlib::IP::Address::V6,
    }
    $ip_ver = $ver ? {
        4 => 'ip',
        6 => 'ip6',
    }
    if $ips != undef {
        $ip_addrs = $ips.filter |$host| { $host =~ $type_ver }.sort.unique
        if $ip_addrs.empty() {
            $ip_stmts = undef
        } else {
            $ip_stmts = [ "${ip_ver} ${dir} { ${ip_addrs.join(', ')} }" ]
        }
    } else {
        $ip_addrs = []
        $ip_stmts = []
    }

    if $sets != undef {
        $set_stmts = $sets.map |$set| { "${ip_ver} ${dir} @${set}_ipv${ver}" }
    } else {
        $set_stmts = []
    }

    if $ip_stmts == undef {
        if $set_stmts == [] {
            $stmts = undef
        } else {
            $stmts = $set_stmts
        }
    } else {
        $stmts = $ip_stmts + $set_stmts
    }

    $stmts
}
