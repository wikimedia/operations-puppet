# SPDX-License-Identifier: Apache-2.0
# Load Balancer for Pontoon

# The load balancer implementation has the following features:
# 1. HTTP(S) services only
# 2. L4 proxying, i.e. no direct server return
#
# As a result the default load balancer will:
# * use backend hosts from the service's "role" configuration (from service::catalog)
# * select backends based on Host header or SNI (no private material required)
# * assume all services are deployed on all internal domains (via pontoon::service_names)
#
# Additional availability can be provided by the network and/or by pointing clients to an healthy
# load balancer via service discovery.
#
# The service discovery layer operates via a local DNS server to provide addresses.
# Refer to 'pontoon::sd' class for the service discovery implementation details and
# 'profile::pontoon:sd' for integration with puppet.git

# Usage (LB + SD)
#
# To enable load balanced services in your Pontoon stack make sure to have the following:
# - at least one service running its 'role' service::catalog parameter
# - one host running role 'pontoon::lb'
# - include 'profile::pontoon::sd' in a base class of some kind. For extra safety
#   the profile should be included before writing /etc/resolv.conf
# - include a suitable sd_*.yaml file in your stack's hiera directory.

class pontoon::lb (
    Hash[String, Wmflib::Service] $services_config,
) {
    $names = pontoon::service_names($services_config)
    $t = $services_config.map |$service_name, $config| {
        $hosts = pontoon::hosts_for_role($config['role'])

        [
            $service_name,
            {
                'names'           => $names[$service_name],
                'port'            => $config['port'],
                'hosts'           => $hosts,
                'backend_use_tls' => $config['encryption'],
            }
        ]
    }

    $services = Hash($t)
    $ports = unique($services.map |$name, $svc| { $svc['port'] })

    haproxy::site { 'pontoon_lb':
        content => template('pontoon/haproxy.lb.erb'),
    }
}
