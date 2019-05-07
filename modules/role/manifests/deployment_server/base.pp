# Mediawiki Deployment Server base class
class role::deployment_server::base {
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::mediawiki::common
    include ::profile::mediawiki::deployment::server
    include ::profile::keyholder::server
    include ::profile::mediawiki::nutcracker
    include ::profile::conftool::client
    include ::scap::master
    include ::profile::scap::dsh
    include ::scap::ferm
}
