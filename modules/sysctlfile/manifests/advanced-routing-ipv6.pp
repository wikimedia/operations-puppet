# sysctl values for advanced routing ipv6
class sysctlfile::advanced-routing-ipv6($ensure="present") {
    sysctlfile {'advanced-routing-ipv6':
        source => 'puppet:///modules/sysctlfile/50-advanced-routing-ipv6.conf',
        number_prefix => '50',
        ensure => $ensure,
        notify => Exec["/sbin/start procps"],
    }
}
