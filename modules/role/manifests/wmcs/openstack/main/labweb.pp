# All horizon/striker/wikitech profiles should fold into
# role::wmcs::openstack::main::web when labweb* is finished
class role::wmcs::openstack::main::labweb {
    system::role { $name: }

    include ::profile::ldap::client::labs
    include ::profile::base::firewall
    include ::profile::openstack::main::nutcracker
    include ::role::lvs::realserver

    # Wikitech:
    include ::profile::openstack::main::wikitech::web
    include ::profile::openstack::main::wikitech::monitor

    # Horizon:
    include ::profile::openstack::main::horizon::dashboard_source_deploy

    # Striker:
    include ::profile::wmcs::striker::web
    include ::profile::waf::apache2::administrative
}
