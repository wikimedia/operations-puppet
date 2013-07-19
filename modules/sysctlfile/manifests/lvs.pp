# sysctl values for lvs
class sysctlfile::lvs($ensure="present") {
    sysctlfile {'lvs':
        source => 'puppet:///modules/sysctlfile/50-lvs.conf',
        number_prefix => '50',
        ensure => $ensure,
        notify => Exec["/sbin/start procps"],
    }
}
