# Mediawiki Deployment Server (prod)
class role::deployment_server {
    include ::standard
    include ::profile::base::firewall
    include ::profile::mediawiki::deployment::server
    include ::profile::backup::host
    include ::role::deployment::mediawiki
    include ::profile::releases::mediawiki::security
    include ::profile::releases::upload
    include ::profile::kubernetes::deployment_server
    include ::profile::mediawiki::web_testing
    backup::set {'home': }
}
