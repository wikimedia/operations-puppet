# All horizon/striker/wikitech profiles should fold into
# role::wmcs::openstack::codfw1dev::web when labweb* is finished
class role::wmcs::openstack::codfw1dev::cloudweb {
    system::role { $name: }

    include ::profile::base::production
    include ::profile::ldap::client::labs
    include ::profile::base::firewall

    # Currently we run both nutcracker and mcrouter.  Nutcracker is for
    #  the soon-to-be-moved wikitech/mediawiki install;
    #  Mcrouter is used by Horizon.  They share the same
    #  memcached backends.
    include ::profile::openstack::codfw1dev::nutcracker
    include ::profile::openstack::codfw1dev::cloudweb_mcrouter

    # Wikitech:
    include ::profile::openstack::codfw1dev::wikitech::web
    include ::profile::openstack::codfw1dev::wikitech::monitor

    # Horizon:
    include ::profile::openstack::codfw1dev::horizon::dashboard_source_deploy

    # Striker:
    include ::profile::docker::ferm
    include ::profile::wmcs::striker::web
    include ::profile::wmcs::striker::docker

    # TLS termination
    include profile::tlsproxy::envoy
}
