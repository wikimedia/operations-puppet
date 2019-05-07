# Mediawiki Deployment Server (prod)
class role::deployment_server {
    include ::profile::standard
    include ::profile::base::firewall

    # Install the scap server components.
    include ::profile::mediawiki::common
    include ::profile::mediawiki::mcrouter_wancache
    include ::profile::prometheus::mcrouter_exporter
    include ::profile::mediawiki::nutcracker
    include ::profile::mediawiki::deployment::server
    include ::profile::scap::dsh
    # Install the keyholder agents
    include ::profile::keyholder::server
    # Install conftool
    include ::profile::conftool::client

    # All needed classes for deploying mediawiki
    include ::profile::releases::mediawiki::security
    include ::profile::releases::upload

    # Kubernetes deployments
    include ::profile::kubernetes::deployment_server

    # apache-fast-test and co.
    include ::profile::mediawiki::web_testing

    include ::profile::backup::host
    backup::set {'home': }
    # proxy for connection to other servers
    include ::profile::services_proxy
}
