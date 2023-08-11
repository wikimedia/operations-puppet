# SPDX-License-Identifier: Apache-2.0
class cloudlb::haproxy::load_all_config (
    CloudLB::HAProxy::Config $cloudlb_haproxy_config,
    Array[Stdlib::Host]      $prometheus_nodes       = [],
) {
    $cloudlb_haproxy_config.each |String $name, CloudLB::HAProxy::Service::Definition $service| {
        cloudlb::haproxy::service { $name:
            service => $service,
        }
    }

    if $prometheus_nodes {
        # for prometheus statistics
        ferm::service { 'metrics_9900':
            ensure => present,
            proto  => 'tcp',
            port   => 9900,
            srange => $prometheus_nodes,
        }
    }
}
