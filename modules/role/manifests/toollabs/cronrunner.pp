class role::toollabs::cronrunner {
    include ::toollabs::cronrunner

    system::role { 'role::toollabs::cronrunner':
        description => 'Tool Labs cron starter host',
    }
}
