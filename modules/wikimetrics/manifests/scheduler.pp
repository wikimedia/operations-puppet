# == Class: wikimetrics::scheduler
# Sets up the celery beat based scheduler for wikimetrics
# This is done by launching the wikimetrics init script,
# with the scheduler mode and passing relevant config files.
# The scheduler runs recurrent reports

class wikimetrics::scheduler {
    require wikimetrics::base

    $mode             = 'scheduler'
    $config_path      = $::wikimetrics::base::config_path
    $venv_path        = $::wikimetrics::base::venv_path

    base::service_unit { 'wikimetrics-scheduler':
        systemd => true,
    }
}
