class profile::dumps::web::statusfiles_sync(
    $rsyncer_settings = hiera('profile::dumps::rsyncer'),
) {
    $mntpoint = $rsyncer_settings['dumps_mntpoint']
    class {'::dumps::web::statusfiles':
        xmldumpsdir => "${mntpoint}/xmldatadumps/public",
    }
}
