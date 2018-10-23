# sonofgridengine/hostgroup.pp

define sonofgridengine::hostgroup(
    $rname  = $title,
    $config = undef,
) {

    sonofgridengine::resource { $rname:
        dir    => 'hostgroups',
        config => $config,
    }
}
