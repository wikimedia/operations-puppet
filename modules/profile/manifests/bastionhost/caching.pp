class role::bastion::caching {
    system::role { $name: }
    class{'::profile::bastion::general'}
    class{'::ipmi::mgmt'}
    class{'::installserver::tftp'}
    class{'::prometheus::ops'}
