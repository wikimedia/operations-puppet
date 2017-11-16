# Mediawiki Deployment Server (labs)
class role::deployment_server::base {
    include ::standard
    include ::profile::base::firewall
    include ::profile::mediawiki::deployment::server
    include ::role::deployment::mediawiki
}
