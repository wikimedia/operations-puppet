# SPDX-License-Identifier: Apache-2.0
# @summary generates haproxy backends for wiki replicas using confd
class cloudlb::haproxy::wikireplicas::backend (
    Array[String[1]]           $replica_types,
    Hash[String, Stdlib::Port] $sections,
) {
    $keys = $replica_types.map |String[1] $type| {
        $sections.keys.map |String[1] $section| { "/wikireplica-db-${type}/${section}" }
    }.flatten.sort

    confd::file { '/etc/haproxy/conf.d/wiki-replica-backends.cfg':
        prefix     => "/pools/${::site}",
        watch_keys => $keys,
        content    => template('cloudlb/haproxy/wikireplicas/backend.cfg.tpl.erb'),
        check      => '/usr/sbin/haproxy -c -V -f /etc/haproxy/haproxy.cfg -f',
        reload     => '/usr/bin/systemctl reload haproxy.service',
    }
}
