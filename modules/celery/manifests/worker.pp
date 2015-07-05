class celery::worker(
    $app,
    $working_dir,
    $user,
    $group,
    $celery_bin_path = '/usr/bin/celery'
) {
    base::service_unit { 'celery':
        systemd => true,
    }
}
