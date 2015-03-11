# gridengine/resourcedir.pp

define gridengine::resourcedir(
    $addcmd,
    $modcmd,
    $delcmd,
    $dir = $title,
){
    $etcdir     = '/var/lib/gridengine/etc'
    $confdir    = "${etcdir}/${dir}"
    $trackerdir = "${etcdir}/tracker/${dir}"

    file { $confdir:
        ensure  => directory,
        force   => $local,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0775',
        recurse => $local,
        purge   => $local,
    }

    file { $trackerdir:
        ensure  => directory,
        force   => true,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0775',
        recurse => false,
        purge   => false,
    }

    exec { "track-${dir}":
        command => "${etcdir}/bin/tracker '${confdir}' '${trackerdir}' '${addcmd}' '${modcmd}' '${delcmd}'",
        require => File[ "${etcdir}/bin/tracker", $confdir, $trackerdir ],
    }

}

