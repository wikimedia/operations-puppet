# Temporary solution until someone has input about what to do with base::firewall
class profile::base::firewall (
    Array[Stdlib::IP::Address] $cumin_masters = hiera('cumin_masters', []),
    Array[Stdlib::IP::Address] $bastion_hosts = hiera('bastion_hosts', []),
    Array[Stdlib::IP::Address] $cache_hosts = hiera('cache_hosts', []),
) {
    class { '::base::firewall':
        cumin_masters => $cumin_masters,
        bastion_hosts => $bastion_hosts,
        cache_hosts   => $cache_hosts,
    }
}
