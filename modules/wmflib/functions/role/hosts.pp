# @summary function to return a list of hosts running a specific role
#  This function relies on data being present in puppetdb.  This means that new nodes will
#  be returned after their first successful puppet run using the specified role.  It also means
#  that nodes will be removed from the results once they have been purged from puppetdb.  This currently
#  happens when a server has failed to run puppet for 14 days
# @param role the role to search for
# @param optional list of sites if present filter to output based on the sites passed
function wmflib::role::hosts (
    Pattern[/\A\w+(::\w+)*\z/]                   $role,
    Variant[Wmflib::Sites, Array[Wmflib::Sites]] $location = [],
) >> Array[Stdlib::Host] {

    $_role = $role.capitalize.stdlib::start_with('Role::') ? {
        true    => $role,
        default => "Role::${role}",
    }
    wmflib::class::hosts($_role, $location)
}
