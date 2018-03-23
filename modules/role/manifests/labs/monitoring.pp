class role::labs::monitoring {
    system::role { 'labs::monitoring': }
    include ::role::labs::graphite
    include ::role::labs::prometheus
    include ::profile::grafana
    include standard
    include ::base::firewall
    class { '::profile::openstack::base::clientlib':
        version => hiera('profile::openstack::main::version'),
    }
}
