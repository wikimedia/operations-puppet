class profile::openstack::eqiad1::metrics(
    $cpu_allocation_ratio = hiera('profile::openstack::eqiad1::metrics::cpu_allocation_ratio'),
    $ram_allocation_ratio = hiera('profile::openstack::eqiad1::metrics::ram_allocation_ratio'),
    $disk_allocation_ratio = hiera('profile::openstack::eqiad1::metrics::disck_allocation_ratio'),
    $listen_port = hiera('profile::openstack::eqiad1::metrics::prometheus_listen_port'),
    $cache_refresh_interval = hiera('profile::openstack::eqiad1::metrics::cache_refresh_interval'),
    $cache_file = hiera('profile::openstack::eqiad1::metrics::cache_file'),
    $schedulable_instance_size = hiera('profile::openstack::eqiad1::metrics::schedulable_instance_size'),
    $region = hiera('profile::openstack::eqiad1::region'),
    $keystone_host = hiera('profile::openstack::eqiad1::keystone_host'),
    $observer_password = hiera('profile::openstack::eqiad1::observer_password'),
  ) {

    require ::profile::openstack::eqiad1::observerenv
    class {'::profile::openstack::base::metrics':
        cpu_allocation_ratio      => $cpu_allocation_ratio,
        ram_allocation_ratio      => $ram_allocation_ratio,
        disk_allocation_ratio     => $disk_allocation_ratio,
        listen_port               => $listen_port,
        cache_refresh_interval    => $cache_refresh_interval,
        cache_file                => $cache_file,
        schedulable_instance_size => $schedulable_instance_size,
        region                    => $region,
        keystone_host             => $keystone_host,
        observer_password         => $observer_password,
    }
    contain '::profile::openstack::base::metrics'
}
