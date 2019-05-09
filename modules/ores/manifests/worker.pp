class ores::worker(
    $log_level = 'ERROR',
) {
    require ::ores::base

    celery::worker { 'ores-worker':
        app             => 'ores_celery.application',
        working_dir     => $ores::base::config_path,
        user            => 'www-data',
        group           => 'www-data',
        celery_bin_path => "${ores::base::venv_path}/bin/celery",
        log_level       => $log_level,
        core_limit      => '10G',
    }
}
