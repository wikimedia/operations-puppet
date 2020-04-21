class profile::openstack::eqiad1::metrics(
    Float                $cpu_allocation_ratio   = lookup('profile::openstack::eqiad1::metrics::cpu_allocation_ratio'),
    Float                $ram_allocation_ratio   = lookup('profile::openstack::eqiad1::metrics::ram_allocation_ratio'),
    Float                $disk_allocation_ratio  = lookup('profile::openstack::eqiad1::metrics::disck_allocation_ratio'),
    Stdlib::Port         $listen_port            = lookup('profile::openstack::eqiad1::metrics::prometheus_listen_port'),
    Integer              $cache_refresh_interval = lookup('profile::openstack::eqiad1::metrics::cache_refresh_interval'),
    Stdlib::Absolutepath $cache_file             = lookup('profile::openstack::eqiad1::metrics::cache_file'),
    Integer              $sched_ram_mbs          = lookup('profile::openstack::eqiad1::metrics::sched_ram_mbs'),
    Integer              $sched_vcpu             = lookup('profile::openstack::eqiad1::metrics::sched_vcpu'),
    Integer              $sched_disk_gbs         = lookup('profile::openstack::eqiad1::metrics::sched_disk_gbs'),
    String               $region                 = lookup('profile::openstack::eqiad1::region'),
    String               $observer_password      = lookup('profile::openstack::eqiad1::observer_password'),
  ) {

    class {'::profile::openstack::base::metrics':
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
        observer_password      => $observer_password,
    }
    contain '::profile::openstack::base::metrics'
}
