# SPDX-License-Identifier: Apache-2.0
function nftables::dscp_stmt(
    Variant[Integer[4,4], Integer[6,6]]  $ver,
    Firewall::Qos                        $qos,
) >> String {
    $dscp = firewall::qos2dscp($qos)
    $ip_ver = $ver ? {
        4 => 'ip',
        6 => 'ip6',
    }
    "${ip_ver} dscp set ${dscp}"
}
