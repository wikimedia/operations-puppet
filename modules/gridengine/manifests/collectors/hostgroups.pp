# gridengine::collectors::hostgroups

define gridengine::collectors::hostgroups($store)
{

    file { $store:
        ensure    => directory,
        owner     => 'root',
        group     => 'root',
        mode      => '0755',
    }

    gridengine::collector { $title:
        dir       => 'hostgroups',
        sourcedir => $store,
        content   => template('gridengine/hostgroup.erb'),
        require   => File[$store],
    }

}
