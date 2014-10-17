# gridengine/resourcedir.pp

define gridengine::resourcedir(
    $etcdir = '/etc/gridengine/local',
    $dir    = $title,
    $local  = true )
{
    file { "$etcdir/$dir":
        ensure  => directory,
        force   => $local,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0775',
        recurse => $local,
        purge   => $local,
    }

    $resourcedir = "$etcdir/.tracker/$dir"

    file { $resourcedir:
        ensure  => directory,
        force   => true,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0775',
        recurse => false,
        purge   => false,
    }

    exec { "purge-deleted-$dir":
        cwd     => $resourcedir,
        path    => '/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin',
        command => "for r in *; do if [ ! -f $etcdir/$dir/\$r ]; then /bin/bash \$r && rm \$f; fi; done",
        require => File[$resourcedir],
    }

}

