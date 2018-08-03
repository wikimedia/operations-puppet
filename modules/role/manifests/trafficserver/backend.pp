class role::trafficserver::backend {
    include ::standard
    include ::profile::trafficserver::backend

    system::role { 'role::trafficserver::backend':
        description => 'Apache Traffic Server backend',
    }
}
