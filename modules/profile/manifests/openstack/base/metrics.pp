class profile::openstack::base::metrics(
    Float                $cpu_allocation_ratio   = lookup('profile::openstack::base::metrics::cpu_allocation_ratio'),
    Float                $ram_allocation_ratio   = lookup('profile::openstack::base::metrics::ram_allocation_ratio'),
    Float                $disk_allocation_ratio  = lookup('profile::openstack::base::metrics::disck_allocation_ratio'),
    Stdlib::Port         $listen_port            = lookup('profile::openstack::base::metrics::prometheus_listen_port'),
    Integer              $cache_refresh_interval = lookup('profile::openstack::base::metrics::cache_refresh_interval'),
    Stdlib::Absolutepath $cache_file             = lookup('profile::openstack::base::metrics::cache_file'),
    Integer              $sched_ram_mbs          = lookup('profile::openstack::base::metrics::sched_ram_mbs'),
    Integer              $sched_vcpu             = lookup('profile::openstack::base::metrics::sched_vcpu'),
    Integer              $sched_disk_gbs         = lookup('profile::openstack::base::metrics::sched_disk_gbs'),
    String               $region                 = lookup('profile::openstack::base::region'),
    String               $observer_password      = lookup('profile::openstack::base::observer_password'),
  ) {

    class {'::profile::prometheus::openstack_exporter':
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
    contain '::profile::prometheus::openstack_exporter'
}
