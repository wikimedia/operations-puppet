# sysctl values for high bandwidth rsyn
class sysctlfile::high-bandwidth-rsync($ensure="present") {
    sysctlfile {'high-bandwidth-rsync':
        source => 'puppet:///modules/sysctlfile/60-high-bandwidth-rsync.conf',
        ensure => $ensure,
        notify => Exec["/sbin/start procps"],
    }
}
