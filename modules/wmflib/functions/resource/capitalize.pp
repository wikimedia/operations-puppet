# SPDX-License-Identifier: Apache-2.0
# @summery ensure a resource is capitilised correctl
# @param resource
# @example "foo::bar".wmflib::resource_capitalize => Foo::Bar
function wmflib::resource::capitalize (
    Wmflib::Resource::Type $resource,
) >> String[1] {
    $resource.split('::').capitalize.join('::')
}
