# gridengine/hostgroup.pp

define gridengine::hostgroup(
    $etcdir  = '/etc/gridengine/local',
    $name    = $title,
    $source  = undef,
    $content = undef )
{

    gridengine::resource { $name:
        etcdir  => $etcdir,
        dir     => 'hostgroups',
        source  => $source,
        content => $content,
        addcmd  => '/usr/bin/qconf -Ahgrp',
        modcmd  => '/usr/bin/qconf -Mhgrp',
        delcmd  => '/usr/bin/qconf -dhgrp',
    }

}

