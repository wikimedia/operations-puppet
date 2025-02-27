class role::thanos::frontend {
    include profile::base::production
    include profile::firewall

    include profile::lvs::realserver
    include profile::lvs::realserver::ipip

    include profile::tlsproxy::envoy

    include profile::thanos::swift::frontend
}
