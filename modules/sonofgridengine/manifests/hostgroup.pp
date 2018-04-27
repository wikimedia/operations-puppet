# sonofgridengine/hostgroup.pp

define sonofgridengine::hostgroup(
    $rname  = $title,
    $config = undef,
) {

    gridengine::resource { $rname:
        dir    => 'hostgroups',
        config => $config,
    }
}
