# gridengine::collectors::hostgroups

define gridengine::collectors::hostgroups($store)
{

    gridengine::collector { $title:
        dir       => 'hostgroups',
        sourcedir => $store,
        content   => template('gridengine/hostgroup.erb'),
        require   => File[$store],
    }

}
