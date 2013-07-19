# sysctl values for ipv6-disable-ra
class sysctlfile::ipv6-disable-ra($ensure="present") {
    sysctlfile {'ipv6-disable-ra':
        source => 'puppet:///modules/sysctlfile/50-ipv6-disable-ra.conf',
        number_prefix => '50',
        ensure => $ensure,
        notify => Exec["/sbin/start procps"],
    }
}
