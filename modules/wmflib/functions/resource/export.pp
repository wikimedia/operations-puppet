# SPDX-License-Identifier: Apache-2.0
function wmflib::resource::export (
    Wmflib::Resource::Type $resource,
    String[1]              $resource_title,
    Hash                   $parameters      = {},
) {
    $title_prefix = 'wmflib::resource::export'
    $_title = "@@${title_prefix}||${resource_title}"
    create_resources($resource.downcase, { $_title => $parameters })
}
