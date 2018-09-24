class profile::openstack::base::metrics(
    $prometheus_nodes = hiera('prometheus_nodes'),
    $cpu_allocation_ratio = hiera('profile::openstack::base::metrics::cpu_allocation_ratio'),
    $ram_allocation_ratio = hiera('profile::openstack::base::metrics::ram_allocation_ratio'),
    $disk_allocation_ratio = hiera('profile::openstack::base::metrics::disck_allocation_ratio'),
    $listen_port = hiera('profile::openstack::base::metrics::prometheus_listen_port'),
    $cache_refresh_interval = hiera('profile::openstack::base::metrics::cache_refresh_interval'),
    $cache_file = hiera('profile::openstack::base::metrics::cache_file'),
    $schedulable_instance_size = hiera('profile::openstack::base::metrics::schedulable_instance_size'),
    $region = hiera('profile::openstack::base::region'),
    $keystone_host = hiera('profile::openstack::base::keystone_host'),
    $observer_password = hiera('profile::openstack::base::observer_password'),
  ) {

    class {'::profile::prometheus::openstack_exporter':
        prometheus_nodes          => $prometheus_nodes,
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
    contain '::profile::prometheus::openstack_exporter'
}
