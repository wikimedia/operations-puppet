# SPDX-License-Identifier: Apache-2.0
# @summary Realise a set of exported resources but filter out duplicats.
# # this allow multiple hosts to export resources with the same title but we only realise one
#   When realising resources parameters are merged with undetermined preference
#   as such all resources should have the same set of parameters
# @param resource the resource type to search for
# @param resource_title a regex to use when seraching for the title
# @param parameters a hash of parameters to filter on
# @param merge_content if true and resoure == 'File' merge the contents parameter
function wmflib::resource::import (
    Wmflib::Resource::Type $resource,
    Optional[String[1]]    $resource_title = undef,
    Hash                   $parameters     = {},
    Boolean                $merge_contents = false,
) >> Hash[String, Hash] {
    if wmflib::have_puppetdb {
        $_resource = wmflib::resource::capitalize($resource)
        $_title = $resource_title ? {
            undef   => '',
            # TODO: i suspect classes cant be exported but not sure
            'Class' => "and title = \"${wmflib::resource::capitalize($resource_title)}\"",
            default => "and title = \"${resource_title}\"",
        }
        $_paramters = $parameters.empty ? {
            true    => '',
            default => $parameters.reduce('') |$memo, $value| { "${memo} and parameters.${value[0]} = \"${value[1]}\"" }
        }
        $pql = @("PQL")
        resources[parameters, title] {
            type = "${_resource}" and exported = true
            ${_title}
            ${_paramters}
        }
        | PQL
        # Following is useful for debugging, we should add proper spec tests
        # notify { $pql: }
        $unique_resources = puppetdb_query($pql).reduce({}) |$memo, $resource| {
            # TODO: when we export we prfix the title with the following
            # wmflib::resource::export||
            # feels like we could do something better here.
            $clean_title = $resource['title'].split('\|\|')[1]
            if $merge_contents and $clean_title in $memo and 'content' in $resource['parameters'] {
                $content = "${memo[$clean_title]['content']}${resource['parameters']['content']}"
                $parameters = $resource['parameters'] + { 'content' => $content }
            } else {
                $parameters = $resource['parameters']
            }
            $memo + { $clean_title => $parameters }
        }
        unless $unique_resources.empty {
            create_resources($resource.downcase, $unique_resources)
        }
        # Useful to return this for testing if nothing else
        $unique_resources
    } else {
        # Then we are running via puppet apply i.e. bolt/beaker
        warning('puppetdb functions not avaliable')
        Hash([])
    }
}
