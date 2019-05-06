# Mediawiki Deployment Server (prod)
class role::deployment_server {
    require role::deployment_server::base
    # All needed classes for deploying mediawiki
    include ::profile::mediawiki::mcrouter_wancache
    include ::profile::prometheus::mcrouter_exporter
    include ::profile::releases::mediawiki::security
    include ::profile::releases::upload
    include ::profile::kubernetes::deployment_server
    include ::profile::mediawiki::web_testing
    include ::profile::backup::host
    backup::set {'home': }
    # proxy for connection to other servers
    include ::profile::services_proxy
}
