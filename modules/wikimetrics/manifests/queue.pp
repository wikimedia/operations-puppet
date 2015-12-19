# == Class: wikimetrics::queue
# Sets up the celery queue for wikimetrics
# This is done by launching the wikimetrics init script,
# with the queue mode and passing relevant config files

class wikimetrics::queue {
    require wikimetrics::base

    base::service_unit { 'wikimetrics-queue':
        systemd => true,
    }
}
