# SPDX-License-Identifier: Apache-2.0
# Configure a TLS terminator and load balancer for public-facing services.

# In this setting there are two classes of public services in production:
# * without LVS: services live on hosts with public IPs (e.g. alerts.w.o, icinga.w.o).
# * with LVS: services are TLS-terminated by edge caches and TLS connections are made to the
#   service's .discovery.wmnet name.

# One of the requirements is for backend host configurations to work in production as-is
# (e.g. virtualhost configuration).

# However, a few assumptions are made to keep things simple:
# * the discovery name is <service_name>.discovery.wmnet
#   (service_name is the key in 'service::catalog' hash)
# * TLS connections to backends are not validated
# * services without LVS also have an entry in service::catalog
# * the list of hosts is taken from the service::catalog "role" key

class pontoon::public_lb (
    Hash[String, Wmflib::Service] $services_config,
    String $public_domain,
) {
    $t = $services_config.map |$service_name, $config| {
        $server_name = "${config['public_endpoint']}.${public_domain}"

        if 'public_aliases' in $config {
            $aliases = $config['public_aliases'].map |$a| { "${a}.${public_domain}" }
        } else {
            $aliases = []
        }

        [
            $service_name,
            {
                'public_name'     => $server_name,
                'public_aliases'  => $aliases,
                'port'            => $config['port'],
                'hosts'           => pontoon::hosts_for_role($config['role']),
                'backend_use_tls' => $config['encryption'],
                # Which SNI to send when talking to backends in TLS.
                'backend_sni'     => ('lvs' in $config) ? {
                                        true  => "${service_name}.discovery.wmnet",
                                        false => $server_name,
                                      },
            }
        ]
    }
    $services = Hash($t)

    haproxy::site { 'pontoon_public_lb':
        content => template('pontoon/haproxy.public.erb'),
    }
}
