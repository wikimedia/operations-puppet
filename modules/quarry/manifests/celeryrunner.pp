# = Class: quarry::celeryrunner
#
# Runs queries submitted via celery
class quarry::celeryrunner {
    include quarry::base

    $clone_path  = '/srv/quarry'

    celery::worker { 'quarry-worker':
        app         => 'quarry.web.worker',
        working_dir => $clone_path,
        user        => 'quarry',
        group       => 'quarry',
    }
}
