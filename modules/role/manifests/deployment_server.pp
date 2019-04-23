# Mediawiki Deployment Server (prod)
class role::deployment_server {
    include ::profile::standard
    include ::profile::base::firewall
    # All needed classes for deploying mediawiki
    include ::profile::mediawiki::common
    include ::profile::mediawiki::deployment::server
    include ::profile::mediawiki::mcrouter_wancache
    include ::profile::prometheus::mcrouter_exporter
    include ::profile::backup::host
    include ::role::deployment::mediawiki
    include ::profile::releases::mediawiki::security
    include ::profile::releases::upload
    include ::profile::kubernetes::deployment_server
    include ::profile::mediawiki::web_testing
    backup::set {'home': }
    # proxy for connection to other servers
    include ::profile::services_proxy
}
