# = Class: quarry::celeryrunner
#
# Runs queries submitted via celery
class quarry::celeryrunner {
    require ::quarry::base

    celery::worker { 'quarry-worker':
        app         => 'quarry.web.worker',
        working_dir => $quarry::base::clone_path,
        user        => 'quarry',
        group       => 'quarry',
    }
}
