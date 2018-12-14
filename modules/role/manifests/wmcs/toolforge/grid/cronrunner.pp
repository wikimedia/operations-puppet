class role::wmcs::toolforge::grid::cronrunner {
    system::role { $name:
        description => 'Toolforge gridengine cron runner'
    }

    include profile::toolforge::base
    include profile::toolforge::apt_pinning
    include profile::toolforge::grid::base
    include profile::toolforge::grid::submit_host
    include profile::toolforge::grid::cronrunner
}
