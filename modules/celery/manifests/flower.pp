define celery::flower(
    $app,
    $working_dir,
    $user,
    $group,
    $celery_bin_path = '/usr/bin/celery',
    $port = 5555,
    $ip = '127.0.0.1',
) {
    base::service_unit { "flower-${title}":
        template_name => 'flower',
        systemd       => true,
    }
}
