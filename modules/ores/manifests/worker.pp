class ores::worker {


    celery::worker { 'ores-worker':
        app             => 'ores_celery.application',
        working_dir     => $ores::base::config_path,
        user            => 'www-data',
        group           => 'www-data',
        celery_bin_path => "${ores::base::venve_path}/bin/celery",
    }
}
