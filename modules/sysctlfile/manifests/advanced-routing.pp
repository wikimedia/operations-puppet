# sysctl values for 'advanced routing'
class sysctlfile::advanced-routing($ensure='present') {
    sysctlfile {'advanced-routing':
        source => 'puppet:///modules/sysctlfile/50-advanced-routing.conf',
        number_prefix => '50',
        ensure => $ensure,
        notify => Exec["/sbin/start procps"],
    }
}
