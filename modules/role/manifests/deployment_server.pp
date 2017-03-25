# Mediawiki Deployment Server
class role::deployment_server {
    include ::standard
    include ::base::firewall
    include ::profile::mediawiki::deployment::server
    include ::role::deployment::mediawiki

    if $::realm != 'labs' {
        include ::role::microsites::releases::upload
        include ::role::backup::host
        backup::set {'home': }
    }

}
