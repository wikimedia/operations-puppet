class role::wmcs::monitoring {
    system::role { $name: }

    include ::profile::standard
    include ::profile::grafana
    include ::profile::base::firewall
    include ::profile::wmcs::graphite
    include ::profile::wmcs::monitoring
    include ::profile::wmcs::prometheus
    include ::profile::openstack::eqiad1::observerenv
    include ::profile::statsite
}
