# SPDX-License-Identifier: Apache-2.0
# @param resource The resource to create e.g. file, concat
# @param resource_title The title of the resource to create
# @param original_title The original title of the calling resource, this is used to ensure
#        the exported resource has a unuiq title
# @param parameters a hash of parameters for the exported resource
function wmflib::resource::export (
    Wmflib::Resource::Type $resource,
    String[1]              $resource_title,
    String[1]              $original_title,
    Hash                   $parameters      = {},
) {
    # Currently the title prefix is not used but it may be useful in future
    $title_prefix = 'wmflib::resource::export'
    $_title = "${title_prefix}-${original_title}||${resource_title}"
    create_resources("@@${resource.downcase}", { $_title => $parameters })
}
