# SPDX-License-Identifier: Apache-2.0
# == Class: profile::zuul::haproxy
# Provision an HAProxy instance for the zuul Cloud VPS project
#
# === Parameters:
# [*kubernetes_hosts*]
#   List of FQDNs of Kubernetes API hosts to expose
class profile::zuul::haproxy (
    Array[Stdlib::Fqdn] $kubernetes_hosts = lookup('profile::zuul::haproxy::kubernetes_hosts'),
) {
    class { 'haproxy::cloud::base': }

    file { '/etc/haproxy/conf.d/kubernetes.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => epp(
            'profile/zuul/haproxy/kubernetes.cfg.epp',
            {
                kubernetes_hosts => $kubernetes_hosts,
            },
        ),
        notify  => Service['haproxy'],
    }
}
