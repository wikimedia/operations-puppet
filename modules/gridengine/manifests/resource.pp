# gridengine/resource.pp

define gridengine::resource(
    $dir,
    $rname   = $title,
    $config  = undef )
{
    $etcdir  = '/var/lib/gridengine/etc'
    $conf    = "${etcdir}/${dir}/${rname}"

    if $config {
        file { $conf:
            ensure  => file,
            owner   => 'sgeadmin',
            group   => 'sgeadmin',
            mode    => '0664',
            content => template($config),
        }
    } else {
        file { $conf:
            ensure  => absent,
        }
    }

}

