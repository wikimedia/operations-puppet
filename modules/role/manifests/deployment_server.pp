# MediaWiki Deployment Server (prod)
class role::deployment_server {
    include profile::standard
    include profile::base::firewall

    # Install the scap server components.
    include profile::mediawiki::common
    include profile::mediawiki::mcrouter_wancache
    include profile::mediawiki::nutcracker
    include profile::mediawiki::deployment::server
    include profile::scap::dsh
    # Install the keyholder agents
    include profile::keyholder::server
    # Install conftool
    include profile::conftool::client

    # All needed classes for deploying mediawiki
    include profile::releases::mediawiki::security
    include profile::releases::upload

    # Kubernetes deployments
    include profile::kubernetes::deployment_server

    include profile::httpbb

    include profile::backup::host
    backup::set {'home': }
    # proxy for connection to other servers
    include profile::services_proxy::envoy

    # in cloud mount a second disk as /srv
    if $::realm == 'labs' {
        require profile::labs::lvm::srv
    }

    system::role { 'deployment_server':
        description => 'Deployment server for MediaWiki and related code',
    }
}
