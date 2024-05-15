# SPDX-License-Identifier: Apache-2.0
# Load Balancer for Pontoon

# The load balancer implementation has the following features:
# 1. HTTP(S) services only
# 2. L4 proxying for internal services, i.e. no direct server return
# 3. L7 proxying for public services
#
# As a result the default load balancer will:
# * use backend hosts from the service's "role" configuration (from service::catalog)
# * select backends based on Host header or SNI (no private material required on the LB host)
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
# - include sd_cloudvps.yaml file in your stack's hiera directory.

class pontoon::lb (
    Hash[String, Wmflib::Service] $services_config,
    String $public_domain,
) {
    ensure_packages('hatop')

    $names = pontoon::service_names($services_config)
    $names_public = pontoon::service_names_public($services_config, $public_domain)
    $t = $services_config.map |$service_name, $config| {
        $hosts = pontoon::hosts_for_role($config['role'])

        [
            $service_name,
            {
                'names'           => $names[$service_name],
                'names_public'    => $names_public[$service_name],
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
