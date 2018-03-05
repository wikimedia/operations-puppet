class profile::dumps::generation::server::dumpstatusfiles_sync(
    $rsyncer_settings = hiera('profile::dumps::rsyncer'),
) {
    $mntpoint = $rsyncer_settings['dumps_mntpoint']
    class {'::dumps::web::dumpstatusfiles':
        xmldumpsdir => "${mntpoint}/xmldatadumps/public",
    }
}
