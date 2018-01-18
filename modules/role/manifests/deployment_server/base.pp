# Mediawiki Deployment Server (labs)
class role::deployment_server::base {
    include ::standard
    include ::base::firewall
    include ::profile::mediawiki::deployment::server
    include ::role::deployment::mediawiki
    include ::profile::releases::mediawiki::security
}
