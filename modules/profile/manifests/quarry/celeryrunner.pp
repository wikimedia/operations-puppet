# = Class: profile::quarry::celeryrunner
#
# Runs queries submitted via celery
class profile::quarry::celeryrunner(
    Stdlib::Unixpath $clone_path = lookup('profile::quarry::base::clone_path'),
    Stdlib::Unixpath $venv_path  = lookup('profile::quarry::base::venv_path'),
) {
    require ::profile::quarry::base

    quarry::worker { 'quarry-worker':
        app             => 'quarry.web.worker',
        working_dir     => $clone_path,
        celery_bin_path => "${venv_path}/bin/celery",
        user            => 'quarry',
        group           => 'quarry',
    }
}
