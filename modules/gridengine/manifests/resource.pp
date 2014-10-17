# gridengine/resource.pp

define gridengine::resource(
    $etcdir  = '/etc/gridengine/local',
    $dir     = '',
    $rname   = $title,
    $source  = undef,
    $content = undef,
    $addcmd  = '',
    $modcmd  = '',
    $delcmd  = '' )
{
    $conf    = "$etcdir/$dir/$rname"
    $tracker = "$etcdir/.tracker/$dir/$rname"

    exec { "create-$dir-$rname-tracker":
        creates => $tracker,
        command => "$etcdir/bin/trackpurge $tracker '$delcmd $rname' echo $addcmd $conf"
        require => File[ [ "$etcdir/bin", $conf ] ],
    }

    exec { "modify-$dir-$rname":
        refreshonly => true,
        onlyif      => "/usr/bin/test -r '$tracker' -a '$conf' -nt '$tracker'",
        command     => "$etcdir/bin/trackpurge $tracker '$delcmd $rname' echo $modcmd $conf"
        require     => File["$etcdir/bin"],
        subscribe   => File[$conf],
    }

    file { $conf:
        ensure  => file,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0664',
        source  => $source,
        content => $content,
    }

}

