# Mediawiki Deployment Server (labs)
class role::deployment_server {
    include ::standard
    include ::base::firewall
    include ::profile::mediawiki::deployment::server
    include ::role::deployment::mediawiki
}
