# gridengine/hostgroup.pp

define gridengine::hostgroup(
    $rname  = $title,
    $config = undef )
{

    gridengine::resource { $rname:
        dir     => 'hostgroups',
        source  => $source,
        content => template($config),
    }

}

