# gridengine/resource.pp

define gridengine::resource(
    $dir,
    $rname   = $title,
    $source  = undef,
    $content = undef )
{
    $etcdir  = '/var/lib/gridengine/etc'
    $conf    = "$etcdir/$dir/$rname"

    if $source || $content {
        file { $conf:
            ensure  => file,
            owner   => 'sgeadmin',
            group   => 'sgeadmin',
            mode    => '0664',
            source  => $source,
            content => $content,
        }
    } else {
        file { $conf:
            ensure  => absent,
        }
    }

}

