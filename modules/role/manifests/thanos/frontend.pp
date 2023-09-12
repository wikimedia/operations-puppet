class role::thanos::frontend {
    system::role { 'thanos::frontend':
        description => 'Swift frontend (Thanos cluster)',
    }

    include ::profile::base::production
    include ::profile::firewall

    include ::profile::lvs::realserver

    include ::profile::tlsproxy::envoy

    include ::profile::thanos::swift::frontend
}
