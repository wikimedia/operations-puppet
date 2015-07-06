class ores::worker(
    $branch = 'deploy',
) {

    class { 'ores::base':
        branch => $branch,
    }

    celery::worker { 'ores-worker':
        app             => 'ores.worker',
        working_dir     => $ores::base::config_path,
        user            => 'www-data',
        group           => 'www-data',
        celery_bin_path => "${ores::base::venve_path}/bin/celery",
    }
}
