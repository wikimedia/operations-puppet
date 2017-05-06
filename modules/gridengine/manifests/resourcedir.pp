# gridengine/resourcedir.pp

define gridengine::resourcedir(
    $dir = $title,
) {

    $etcdir     = '/var/lib/gridengine/etc'
    $confdir    = "${etcdir}/${dir}"

    file { $confdir:
        ensure  => directory,
        force   => false,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0775',
        recurse => false,
        purge   => false,
    }

}
