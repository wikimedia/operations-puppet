# filtertags: labs-project-tools
class role::toollabs::cronrunner {
    include ::toollabs::cronrunner

    system::role { 'toollabs::cronrunner':
        description => 'Tool Labs cron starter host',
    }
}
