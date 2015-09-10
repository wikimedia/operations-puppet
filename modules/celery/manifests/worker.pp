define celery::worker(
    $app,
    $working_dir,
    $user,
    $group,
    $celery_bin_path = '/usr/bin/celery',
    $log_level = 'ERROR',
) {
    base::service_unit { "celery-${title}":
        template_name => 'celery',
        systemd       => true,
    }
}
