# = Class: profile::quarry::celeryrunner
#
# Runs queries submitted via celery
class profile::quarry::celeryrunner(
    $clone_path = hiera('profile::quarry::base::clone_path'),
    $venv_path = hiera('profile::quarry::base::venv_path'),
) {
    require ::profile::quarry::base

    celery::worker { 'quarry-worker':
        app             => 'quarry.web.worker',
        working_dir     => $clone_path,
        celery_bin_path => "${venv_path}/bin/celery",
        user            => 'quarry',
        group           => 'quarry',
    }
}
