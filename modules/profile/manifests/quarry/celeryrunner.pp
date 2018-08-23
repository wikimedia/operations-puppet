# = Class: profile::quarry::celeryrunner
#
# Runs queries submitted via celery
class profile::quarry::celeryrunner {
    require ::profile::quarry::base

    celery::worker { 'quarry-worker':
        app         => 'quarry.web.worker',
        working_dir => $quarry::base::clone_path,
        user        => 'quarry',
        group       => 'quarry',
    }
}
