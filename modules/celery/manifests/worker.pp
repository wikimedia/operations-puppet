define celery::worker(
    $app,
    $working_dir,
    $user,
    $group,
    $celery_bin_path = '/usr/bin/celery',
    $log_level = 'ERROR',
    $core_limit = '0',
) {
    systemd::service { "celery-${title}":
        content => systemd_template('celery'),
        restart => true,
    }
}
