class role::wmcs::toolforge::grid::cronrunner {
    system::role { 'wmcs::toolforge::grid::cronrunner': description => 'Toolforge gridengine cron runner' }

    include profile::toolforge::base
    include profile::toolforge::apt_pinning
    include profile::toolforge::grid::base
    include profile::toolforge::grid::cronrunner
}
