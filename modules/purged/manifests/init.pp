# == Class: purged
#
class purged (
    String $backend_addr,
    String $frontend_addr,
    Array[String] $mc_addrs,
    String $prometheus_addr,
    Integer $frontend_workers,
    Integer $backend_workers,
    Boolean $is_active,
) {
    package { 'purged':
        ensure => present,
    }

    $mcast_str = join($mc_addrs, ',')

    $ensure = $is_active? {
        true    => 'present',
        default => 'absent',
    }

    systemd::service { 'purged':
        ensure    => $ensure,
        content   => systemd_template('purged'),
        subscribe => Package['purged'],
    }
}
