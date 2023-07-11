# SPDX-License-Identifier: Apache-2.0
# == Class profile::wmcs::services::etcd_discovery
#
# Etcd-discovery server profile
#
#  The only one of these that would typically need a hiera definition is
#   $prefix_url which should be set to the discovery endpoint host, e.g.
#   https://etcd-discovery.codfw1dev.wmcloud.org
class profile::wmcs::services::etcd_discovery(
    String $prefix_url = lookup('profile::wmcs::services::etcd_discovery::prefix_url',
        { 'default_value' => 'http://example.com' }),
    String $web_service_address = lookup('profile::wmcs::services::etcd_discovery::web_service_address',
        { 'default_value' => ':8087' }),
    String $endpoint_location = lookup('profile::wmcs::services::etcd_discovery::endpoint_location',
        { 'default_value' => 'http://127.0.0.1:2379' }),
){
    ensure_packages(['etcd-discovery', 'etcd-server'])

    service { 'etcd-discovery':
        ensure    => running,
        require   => Package['etcd-discovery'],
        subscribe => File['/etc/etcd-discovery/etcd-discovery.conf'],
    }

    service { 'etcd':
        ensure  => running,
        require => Package['etcd-server'],
    }

    file { '/etc/etcd-discovery/etcd-discovery.conf':
        ensure  => file,
        mode    => '0444',
        content => inline_template(
        "[server]
# used as prefix when returning the cluster ID
prefix_url=<%= @prefix_url %>

# This is the bind address. :8087 works, as well as IP:8087
web_service_address=<%= @web_service_address %>

[etcd]
# Where is located your ETCD cluster?
endpoint_location=<%= @endpoint_location %>"
        ),
    }

    file { '/etc/default/etcd':
        ensure  => file,
        mode    => '0444',
        content => "# etcd-discovery expects v2
DAEMON_ARGS=--enable-v2",
        require => Package['etcd-server'],
        notify  => Service['etcd'],
    }
}
