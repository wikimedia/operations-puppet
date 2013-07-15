# sysctl values for http high performance
class sysctlfile::high-http-performance($ensure="present") {
    sysctlfile {'high-http-performance':
        source => 'puppet:///modules/sysctlfile/60-high-http-performance.conf',
        ensure => $ensure
    }
}
