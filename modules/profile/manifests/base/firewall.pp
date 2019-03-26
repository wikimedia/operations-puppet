# Temporary solution until someone has input about what to do with base::firewall
class profile::base::firewall (
    Array[Stdlib::IP::Address] $cumin_masters = hiera('cumin_masters', []),
) {
    class { '::base::firewall':
        cumin_masters => $cumin_masters,
    }
}
