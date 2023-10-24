class role::wmcs::monitoring {
    system::role { $name: }

    include ::profile::base::production
    include ::profile::grafana
    include ::profile::backup::host # For Grafana backups
    include ::profile::firewall
    include ::profile::base::cloud_production
    include ::profile::tlsproxy::envoy # TLS termination
    include ::profile::openstack::eqiad1::observerenv
    include ::profile::statsite
}
