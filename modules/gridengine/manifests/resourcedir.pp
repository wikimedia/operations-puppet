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

    $trackerdir = "$etcdir/.tracker/$dir"

    file { $trackerdir:
        ensure  => directory,
        force   => true,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0775',
        recurse => false,
        purge   => false,
    }

    exec { "purge-deleted-$dir":
        command => "$etcdir/bin/runpurge $trackerdir $etcdir/$dir",
        require => File[ [ "$etcdir/bin", $trackerdir ] ],
    }

}

