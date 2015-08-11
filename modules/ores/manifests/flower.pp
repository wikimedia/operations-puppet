# = Class: ores::flower
# Sets up a private flower instance to monitor celery
#
# Users should use ssh port forwarding to access the
# instance.
class ores::flower {
    require ores::base

    celery::flower { 'ores':
        app             => 'ores_celery.application',
        working_dir     => $ores::base::config_path,
        user            => 'www-data',
        group           => 'www-data',
        celery_bin_path => "${ores::base::venv_path}/bin/celery",
    }
}
