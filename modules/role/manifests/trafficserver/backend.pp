class role::trafficserver::backend {
    include ::profile::standard
    include ::profile::trafficserver::backend

    # pool/depool/drain scripts
    include ::profile::conftool::client
    class { 'conftool::scripts': }

    system::role { 'role::trafficserver::backend':
        description => 'Apache Traffic Server backend',
    }
}
