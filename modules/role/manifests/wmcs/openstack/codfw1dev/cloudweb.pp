# All horizon/striker/wikitech profiles should fold into
# role::wmcs::openstack::codfw1dev::web when labweb* is finished
class role::wmcs::openstack::codfw1dev::cloudweb {
    system::role { $name: }

    include ::profile::standard
    include ::profile::ldap::client::labs
    include ::profile::base::firewall
    include ::profile::openstack::codfw1dev::nutcracker
    include ::profile::lvs::realserver

    # Wikitech (disabled, probably not useful these days):
    #include ::profile::openstack::codfw1dev::wikitech::web
    #include ::profile::openstack::codfw1dev::wikitech::monitor

    # Horizon:
    include ::profile::openstack::codfw1dev::horizon::dashboard_source_deploy

    # Striker:
    include ::profile::wmcs::striker::web

    include ::profile::waf::apache2::administrative

}
