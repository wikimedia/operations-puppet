# SPDX-License-Identifier: Apache-2.0

# NOTE consider using a Cloud VPS webproxy pointed to role::pontoon::lb
# instead of this role. It will be simpler to manage and not require a
# floating IP allocated to work.
# See also https://wikitech.wikimedia.org/wiki/Help:Using_a_web_proxy_to_reach_Cloud_VPS_servers_from_the_internet#wmcloud.org_zone_delegations

# The Pontoon frontend takes care of the following tasks:
# * Acquire TLS certificates for publicly-available services
# * Proxy traffic from external clients to the service's hosts.

# For a service::catalog entry (i.e. a service) to be considered the following keys must be set:
# * 'port': the service port to proxy traffic to.
# * 'public_endpoint': the service's endpoint to serve under $public_domain.
# * 'role': the service's role. Traffic will be proxied to all hosts running this role.
# * all required keys by service::catalog, namely: description/sites/ip/state
# * 'encryption': recommeded to be set to 'true' but not compulsory

# Due to the simple implementation (there's no certificates distribution amongst frontends)
# there can be only one frontend host active at a time, and all subdomains of $public_domain must be
# routed to the frontend.

class role::pontoon::frontend {
    include profile::base::production
    include profile::firewall

    include profile::pontoon::frontend
}
