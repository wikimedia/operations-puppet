class applicationserver {
    include applicationserver::apache_packages
    include applicationserver::config::base
    include applicationserver::cron
    include applicationserver::service
    include applicationserver::sudo
}
