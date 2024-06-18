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
