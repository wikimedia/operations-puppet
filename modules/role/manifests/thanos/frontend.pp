class role::thanos::frontend {
    system::role { 'thanos::frontend':
        description => 'Thanos (Prometheus long-term storage) frontend',
    }

    include ::profile::standard
    include ::profile::base::firewall

    include ::profile::lvs::realserver

    include ::profile::tlsproxy::envoy

    include ::profile::thanos::query
    include ::profile::thanos::httpd

    include ::profile::thanos::swift::frontend
}
