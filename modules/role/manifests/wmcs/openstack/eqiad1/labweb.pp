# All horizon/striker/wikitech profiles should fold into
# role::wmcs::openstack::eqiad1::web when labweb* is finished
class role::wmcs::openstack::eqiad1::labweb {
    system::role { $name: }

    include ::profile::standard
    include ::profile::ldap::client::labs
    include ::profile::base::firewall
    include ::profile::openstack::eqiad1::nutcracker
    include ::role::lvs::realserver

    # Wikitech:
    include ::profile::openstack::eqiad1::wikitech::web
    include ::profile::openstack::eqiad1::wikitech::monitor

    # Horizon:
    include ::profile::openstack::eqiad1::horizon::dashboard_source_deploy

    # Striker:
    include ::profile::wmcs::striker::web

    include ::profile::waf::apache2::administrative

}
