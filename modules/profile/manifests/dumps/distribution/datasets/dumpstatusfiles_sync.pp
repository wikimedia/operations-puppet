class profile::dumps::distribution::datasets::dumpstatusfiles_sync(
    $rsyncer_settings = lookup('profile::dumps::distribution::rsync_config'),
) {
    $mntpoint = $rsyncer_settings['dumps_mntpoint']
    class {'::dumps::web::dumpstatusfiles':
        xmldumpsdir => "${mntpoint}/xmldatadumps/public",
    }
}
