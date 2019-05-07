# Mediawiki Deployment Server base class
class role::deployment_server::base {
    include ::profile::standard
    include ::profile::base::firewall
    # Install the scap server components.
    include ::profile::mediawiki::common
    include ::profile::mediawiki::nutcracker
    include ::profile::mediawiki::deployment::server
    include ::profile::scap::dsh
    # Install the keyholder agents
    include ::profile::keyholder::server
    # Install conftool
    include ::profile::conftool::client
}
