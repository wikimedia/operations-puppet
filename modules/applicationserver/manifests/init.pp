class applicationserver {
    include applicationserver::config::base
    include applicationserver::cron
    include applicationserver::service
    include applicationserver::sudo
}
