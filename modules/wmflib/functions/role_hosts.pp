# @summary function to return a list of hosts running a specific role
#  This function relies on data being present in puppetdb.  This means that new nodes will
#  be retuned after their first successful puppet run using the specified role.  It also means
#  that nodes will be removed from the results once they have been purged from puppetdb.  This currently
#  happens when a server has failed to tun puppet for 14 days
# @param role the role to search for
# @param optional list of sites if present filter to output based on the sites passed
function wmflib::role_hosts (
    String[1]                                    $role,
    Variant[Wmflib::Sites, Array[Wmflib::Sites]] $location = [],
) {

    $_role = $role.stdlib::start_with('role::') ? {
        true    => $role,
        default => "role::${role}",
    }.split('::').capitalize.join('::')

    # TODO: need a better way to determin site
    # this doesn't work for wikimedia.org domains
    $_location = Array($location, true)
    $site_constraint = $_location.empty ? {
        true    => '',
        default => " and certname ~ \"${_location.join('|')}\"",
    }
    $pql = @("PQL")
    resources[certname] {
        type = "Class" and title = "${_role}"${site_constraint}
    }
    | PQL
    puppetdb_query($pql).map |$resource| { $resource['certname'] }
}
