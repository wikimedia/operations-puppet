# = Class: profile::quarry::celeryrunner
#
# Runs queries submitted via celery
class profile::quarry::celeryrunner(
    $clone_path = hiera('profile::quarry::base::clone_path'),
) {
    require ::profile::quarry::base

    celery::worker { 'quarry-worker':
        app         => 'quarry.web.worker',
        working_dir => $clone_path,
        user        => 'quarry',
        group       => 'quarry',
    }
}
