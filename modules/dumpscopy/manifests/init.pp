class dumpscopy(
    $user = user,
    $sourcedir = sourcedir,
    $dest = dest,
) {
    file { '/usr/local/bin/copy_completed_dumpfiles.py':
        ensure => 'present',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumpsrsync/copy_completed_dumpfiles.py',
    }

    $rsync_args =  "--rsyncargs $source,$dest"
    cron { 'copy-completed-dumpfiles':
        ensure  => 'present',
        command => "/usr/local/bin/copy_completed_dumpfiles.py --basedir ${sourcedir} ${rsyncargs}"
        user    => $user,
        minute  => '20',
        hour    => '3',
    }

}
