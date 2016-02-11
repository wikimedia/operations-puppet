class role::labs::tools::submit {
    include ::toollabs::submit

    system::role { 'role::labs::tools::submit':
        description => 'Tool Labs job submit (cron) host',
    }
}
