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
        path    => '/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin',
        command => "echo $addcmd '$conf' && /bin/echo 'echo $delcmd $rname' >'$tracker'",
        require => File[$conf],
    }

    exec { "modify-$dir-$rname":
        refreshonly => true,
        path        => '/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin',
        onlyif      => "test -r '$tracker' -a '$conf' -nt '$tracker'",
        command     => "echo $modcmd '$conf' && /bin/touch '$tracker'",
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

