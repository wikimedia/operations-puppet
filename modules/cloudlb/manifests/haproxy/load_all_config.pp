# SPDX-License-Identifier: Apache-2.0
class cloudlb::haproxy::load_all_config (
    CloudLB::HAProxy::Config $cloudlb_haproxy_config,
) {
    $cloudlb_haproxy_config.each |String $name, CloudLB::HAProxy::Service::Definition $service| {
        cloudlb::haproxy::service { $name:
            service => $service,
        }
    }
}
