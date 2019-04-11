# sonofgridengine::collectors::hostgroups

define sonofgridengine::collectors::hostgroups($store)
{

    sonofgridengine::collector { $title:
        dir       => 'hostgroups',
        sourcedir => $store,
        config    => 'sonofgridengine/hostgroup.erb',
    }

}
