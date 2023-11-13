# SPDX-License-Identifier: Apache-2.0
# @summary generates haproxy frontends to connect to the wiki replicas
class cloudlb::haproxy::wikireplicas::frontend (
    Hash[String[1], Hash[String[1], Stdlib::IP::Address::Nosubnet]] $frontends,
    Hash[String[1], String[1]]                                      $backups,
) {
    file { '/etc/haproxy/conf.d/wiki-replica-backends.cfg':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('cloudlb/haproxy/wikireplicas/frontend.cfg.erb'),
        notify  => Service['haproxy'],
    }
}
