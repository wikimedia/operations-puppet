class profile::openstack::eqiad1::metrics(
    $nova_controller = hiera('profile::openstack::eqiad1::nova_controller'),
    $cpu_allocation_ratio = hiera('profile::openstack::eqiad1::metrics::cpu_allocation_ratio'),
    $ram_allocation_ratio = hiera('profile::openstack::eqiad1::metrics::ram_allocation_ratio'),
    $disk_allocation_ratio = hiera('profile::openstack::eqiad1::metrics::disck_allocation_ratio'),
    $listen_port = hiera('profile::openstack::eqiad1::metrics::prometheus_listen_port'),
    $cache_refresh_interval = hiera('profile::openstack::eqiad1::metrics::cache_refresh_interval'),
    $cache_file = hiera('profile::openstack::eqiad1::metrics::cache_file'),
    $sched_ram_mbs = hiera('profile::openstack::eqiad1::metrics::sched_ram_mbs'),
    $sched_vcpu = hiera('profile::openstack::eqiad1::metrics::sched_vcpu'),
    $sched_disk_gbs = hiera('profile::openstack::eqiad1::metrics::sched_disk_gbs'),
    $region = hiera('profile::openstack::eqiad1::region'),
    $keystone_host = hiera('profile::openstack::eqiad1::keystone_host'),
    $observer_password = hiera('profile::openstack::eqiad1::observer_password'),
  ) {

    require ::profile::openstack::eqiad1::observerenv
    class {'::profile::openstack::base::metrics':
        nova_controller        => $nova_controller,
        cpu_allocation_ratio   => $cpu_allocation_ratio,
        ram_allocation_ratio   => $ram_allocation_ratio,
        disk_allocation_ratio  => $disk_allocation_ratio,
        listen_port            => $listen_port,
        cache_refresh_interval => $cache_refresh_interval,
        cache_file             => $cache_file,
        sched_ram_mbs          => $sched_ram_mbs,
        sched_vcpu             => $sched_vcpu,
        sched_disk_gbs         => $sched_disk_gbs,
        region                 => $region,
        keystone_host          => $keystone_host,
        observer_password      => $observer_password,
    }
    contain '::profile::openstack::base::metrics'
}
