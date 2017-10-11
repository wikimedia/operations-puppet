# Mediawiki Deployment Server (prod)
class role::deployment_server {
    include ::standard
    include ::profile::base::firewall
    include ::profile::mediawiki::deployment::server
    include ::profile::backup::host
    include ::role::deployment::mediawiki
    include ::profile::releases::upload
    backup::set {'home': }
}
