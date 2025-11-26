# SPDX-License-Identifier: Apache-2.0
function nftables::ip_rules(
    Optional[Array]                      $l3_stmts,
    String                               $port_stmt,
    Array[String]                        $stmts,
    Enum['notrack', 'accept', 'return']  $verdict,
) >> Array {
    if $l3_stmts == undef {
        $rules = [
            [$port_stmt] + $stmts + [$verdict],
        ]
    } else {
        $rules = $l3_stmts
            .unique()
            .map |$l3_stmt| {
                [$l3_stmt, $port_stmt] + $stmts + [$verdict]
            }
    }

    $rule_lines = $rules
        .map |$rule| { $rule.filter |$part| { $part != undef } }
        .map |$rule| { $rule.join(' ') }
        .sort

    $rule_lines
}
