# gridengine/resource.pp

define gridengine::resource(
    $etcdir  = '/etc/gridengine/local',
    $dir     = '',
    $name    = $title,
    $source  = undef,
    $content = undef,
    $addcmd  = '',
    $modcmd  = '',
    $delcmd  = '' )
{
    $conf    = "$etcdir/$dir/$name"
    $tracker = $etcdir/.tracker/$dir/$name"

    exec { "create-$dir-$name-tracker":
        creates => $tracker,
        command => "echo $addcmd '$conf' && /bin/echo 'echo $delcmd $name' >'$tracker'",
        require => File[$conf],
    }

    exec { "modify-$dir-$name":
        refreshonly => true,
        onlyif      => "test -r '$tracker' -a '$conf' -nt '$tracker'",
        command     => "echo $modcmd '$conf' && /bin/touch '$tracker'",
        subscribe   => File[$conf],
    }

    file { $conf:
        ensure  => file,
        owner   => 'sgeadmin',
        group   => 'sgeamind',
        mode    => '0664',
        source  => $source,
        content => $content,
    }

}

