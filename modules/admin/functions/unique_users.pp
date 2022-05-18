# SPDX-License-Identifier: Apache-2.0
# @summary parse data and produce a unique list of users
# @param data the admin data loaded from data.uaml
function admin::unique_users (
    Array[String[1]] $groups,
) >> Array[String[1]] {

    include admin

    $groups.reduce([]) |$memo, $group| {
        if $group in $admin::data['groups'] {
            $memo + $admin::data['groups'][$group]['members']
        } else {
            $memo
        }
    }.flatten.unique
}
