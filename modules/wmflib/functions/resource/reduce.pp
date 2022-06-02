# SPDX-License-Identifier: Apache-2.0
# @summary Realise a set of exported resources but filter out duplicats.
# # this allow multiple hosts to export resources with the same title but we only realise one
#   When realising resources parameters are merged with undetermined preference
#   as such all resources should have the same set of parameters
# @param resource the resource type to search for
# @param resource_title a regex to use when seraching for the title
# @param parameters a hash of parameters to filter on
# @param exported if true filter by exported
# @param realise if true realise the resources
function wmflib::resource::reduce(
    Wmflib::Resource::Type $resource,
    Optional[String[1]]    $resource_title = undef,
    Hash                   $parameters     = {},
    Boolean                $exported       = true,
    Boolean                $realize        = true,
) >> Hash[String, Hash] {
    $_resource = wmflib::resource::capitalize($resource)
    $_exported = $exported.bool2str('and exported = true', '')
    $_title = $_resource ? {
        undef   => '',
        'Class' => "and title=\"${wmflib::resource::capitalize($resource_title)}\"",
        default => "and title=\"${resource_title}\"",
    }
    $_paramters = $parameters.empty ? {
        true    => '',
        default => $parameters.reduce('') |$memo, $value| { "${memo} and parameters.${value[0]} = \"${value[1]}\"" }
    }
    $pql = @("PQL")
    resources[parameters, title] {
        type = "${_resource}"
        ${_title}
        ${_exported}
        ${_paramters}
    }
    | PQL
    $unique_resources = puppetdb_query($pql).reduce({}) |$memo, $resource| {
        $memo + {$resource['title'] => $resource['parameters']}
    }
    if $realize and !$unique_resources.empty {
        create_resources($resource.downcase, $unique_resources)
    }
    $unique_resources
}
