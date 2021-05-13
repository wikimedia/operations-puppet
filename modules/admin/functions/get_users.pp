# SPDX-License-Identifier: Apache-2.0
function admin::get_users (
    Variant[String,Array[String]] $filter = [],
) {
    include admin
    $filter.empty ? {
        true    => $admin::uinfo,
        default => $admin::uinfo.filter |$user, $config| { $user in Array($filter, true) },
    }
}
