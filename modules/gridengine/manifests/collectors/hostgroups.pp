# gridengine::collectors::hostgroups

define gridengine::collectors::hostgroups($store)
{

    gridengine::collector { $title:
        dir       => 'hostgroups',
        sourcedir => $store,
        config    => 'gridengine/hostgroup.erb',
    }

}
