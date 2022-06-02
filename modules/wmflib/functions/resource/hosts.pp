# @summary function to return a list of hosts running a specific resource
#  This function relies on data being present in puppetdb.  This means that new nodes will
#  be returned after their first successful puppet run using the specified resource.  It also means
#  that nodes will be removed from the results once they have been purged from puppetdb.  This currently
#  happens when a server has failed to run puppet for 14 days
# @param resource the resource to search for
# @param optional list of sites if present filter to output based on the sites passed
# @param resource_title the resource title to search for
function wmflib::resource::hosts (
    Wmflib::Resource::Type                       $resource,
    Variant[Wmflib::Sites, Array[Wmflib::Sites]] $location       = [],
    Optional[String[1]]                          $resource_title = undef,
) >> Array[Stdlib::Host] {

    $_resource = wmflib::resource::capitalize($resource)
    $_title = $resource_title ? {
        undef   => '',
        default => " and title = \"${resource_title}\"",
    }

    # TODO: need a better way to determine site
    # this doesn't work for wikimedia.org domains
    $_location = Array($location, true)
    $site_constraint = $_location.empty ? {
        true    => '',
        default => " and certname ~ \"${_location.join('|')}\"",
    }
    $pql = @("PQL")
    resources[certname] {
        type = "${_resource}" ${_title}${site_constraint}
    }
    | PQL
    puppetdb_query($pql).map |$resource| { $resource['certname'] }.sort
}
