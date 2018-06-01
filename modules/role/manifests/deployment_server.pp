# Mediawiki Deployment Server (prod)
class role::deployment_server {
    include ::standard
    include ::base::firewall
    include ::profile::mediawiki::deployment::server
    include ::profile::mediawiki::mcrouter_wancache
    include ::profile::prometheus::mcrouter_exporter
    include ::profile::backup::host
    include ::role::deployment::mediawiki
    include ::profile::releases::mediawiki::security
    include ::profile::releases::upload
    include ::profile::kubernetes::deployment_server
    backup::set {'home': }
}
