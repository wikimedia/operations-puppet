function profile::contacts::get_owners (
) {
    $pql = @("PQL")
    resources[certname,tags,parameters] {
        type = "Class" and title = "Profile::Contacts"
    }
    | PQL
    Hash(wmflib::puppetdb_query($pql).filter |$r| { !$r['parameters']['role_contacts'].empty }.map |$resource| {
        $contacts = $resource['parameters']['role_contacts']
        # We just pick the first one, this should be fine if everything follows the policy
        # but there are a couple of outliers, either way it should be fine
        $role_tag = $resource['tags'].filter |$t| { $t.stdlib::start_with('role::') }[0]
        [$role_tag, $contacts]
    }.sort)
}
