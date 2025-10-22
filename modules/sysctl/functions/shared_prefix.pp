# SPDX-License-Identifier: Apache-2.0
# @summary function to find the longest shared prefix of the supplied sysctls
# @param values hash of sysctl key to value
function sysctl::shared_prefix (
    Hash               $values,
) >> String {
    $split_sysctls = $values.map |$k, $_| {
        split($k, /\./)
    }
    $prefix = $split_sysctls[0].reduce({'i' => 0, 'prefix' => []}) |$memo1, $part| {
        {
            'i' => $memo1['i'] + 1,
            'prefix' => $memo1['prefix'] +
                $split_sysctls.reduce({'j' => 0, 'part'=> $part}) |$memo2, $_| {
                    if $split_sysctls[$memo2['j']][$memo1['i']] == $part {
                        {'j' => $memo2['j'] + 1, 'part' => $memo2['part']}
                    } else {
                        {'j' => $memo2['j'] + 1, 'part' => undef}
                    }
                }['part']
        }
    }['prefix']
    join($prefix.filter |$v| { $v }, '.')
}
