# gridengine/resourcedir.pp

define gridengine::resourcedir(
    $dir = $title,
) {

    $etcdir     = '/var/lib/gridengine/etc'
    $confdir    = "${etcdir}/${dir}"
    $trackerdir = "${etcdir}/tracker/${dir}"

    file { $confdir:
        ensure  => directory,
        force   => false,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0775',
        recurse => false,
        purge   => false,
    }

    file { $trackerdir:
        ensure  => absent,
        force   => true,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0775',
        recurse => false,
        purge   => false,
    }

}
