class applicationserver {
    include applicationserver::config::base
    include applicationserver::service
    include applicationserver::sudo
}
