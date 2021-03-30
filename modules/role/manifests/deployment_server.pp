# MediaWiki Deployment Server (prod)
class role::deployment_server {

    system::role { 'deployment_server':
        description => 'Deployment server for MediaWiki and related code',
    }

    # standards
    include profile::standard
    include profile::base::firewall
    include profile::backup::host
    backup::set {'home': }

    # webserver, scap deployment tool with SSH agent, rsync
    include profile::mediawiki::deployment::server
    include profile::scap::dsh
    include profile::keyholder::server

    # memcached-related 
    include profile::mediawiki::mcrouter_wancache
    include profile::mediawiki::nutcracker

    # client to fetch configuration data
    include profile::conftool::client

    # MediaWiki release uploads to releases servers
    include profile::releases::mediawiki::private
    include profile::releases::mediawiki::security
    include profile::releases::upload

    # Kubernetes deployments
    include profile::kubernetes::deployment_server

    # tool to test webserver config changes
    include profile::httpbb

    # proxy for connection to other servers
    include profile::services_proxy::envoy
}
