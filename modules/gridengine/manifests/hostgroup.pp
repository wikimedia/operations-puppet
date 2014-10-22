# gridengine/hostgroup.pp

define gridengine::hostgroup(
    $hgname  = $title,
    $source  = undef,
    $content = undef )
{

    gridengine::resource { $hgname:
        dir     => 'hostgroups',
        source  => $source,
        content => $content,
    }

}

