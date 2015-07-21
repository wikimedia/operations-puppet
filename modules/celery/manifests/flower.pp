define celery::flower(
    $app,
    $working_dir,
    $user,
    $group,
    $celery_bin_path = '/usr/bin/celery',
) {
    base::service_unit { "flower-${title}":
        template_name => 'flower',
        systemd       => true,
    }
}
