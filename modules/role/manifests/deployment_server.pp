# Mediawiki Deployment Server (prod)
class role::deployment_server {
    include ::standard
    include ::base::firewall
    include ::profile::mediawiki::deployment::server
    include ::profile::backup::host
    include ::role::deployment::mediawiki
    include ::role::microsites::releases::upload
    backup::set {'home': }
}
