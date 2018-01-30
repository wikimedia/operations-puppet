# web interfaces for wmcs admins
# Horizon + Wikitech + Striker
class role::wmcs::web_interfaces {

    include ::standard
    include ::profile::base::firewall
    include ::role::wmcs::openstack::main::horizon
    include ::role::striker::web
    include ::ldap::role::client::labs
}
