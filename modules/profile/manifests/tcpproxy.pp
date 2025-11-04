# SPDX-License-Identifier: Apache-2.0
# sets up a TCP proxy (using HAproxy)
class profile::tcpproxy(
    String $socket = lookup(profile::tcpproxy::socket),
    Optional[Stdlib::Port] $prometheus_port = lookup('profile::tcpproxy::prometheus_port', {'default_value' => 9422}),
){

    ensure_packages(['haproxy'])

    profile::auto_restarts::service { 'haproxy': }

    file { '/etc/haproxy/haproxy.cfg':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0544',
        content => template('profile/tcpproxy/haproxy_tcpproxy.cfg.erb'),
        require => Package['haproxy'],
    }

    firewall::service { 'proxy-gerrit-ssh':
        proto    => 'tcp',
        port     => [29418],
        src_sets => ['CACHES', 'DEPLOYMENT_HOSTS'],
    }
}
