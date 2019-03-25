# filtertags: labs-project-tools
class role::toollabs::cronrunner {
    include ::toollabs::cronrunner

    system::role { 'toollabs::cronrunner':
        description => 'Toolforge cron starter host',
    }
}
