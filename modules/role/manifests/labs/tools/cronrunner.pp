class role::labs::tools::cronrunner {
    include ::toollabs::cronrunner

    system::role { 'role::labs::tools::cronrunner':
        description => 'Tool Labs cron starter host',
    }
}
