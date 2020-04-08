# == Class: purged
#
class purged (
    String $backend_addr,
    String $frontend_addr,
    Array[String] $mc_addrs,
    String $prometheus_addr,
    Integer $concurrency,
) {
    package { 'purged':
        ensure => present,
    }

    $mcast_str = join($mc_addrs, ',')

    systemd::service { 'purged':
        content   => systemd_template('purged'),
        subscribe => Package['purged'],
    }
}
