# All horizon/striker/wikitech profiles should fold into
# role::wmcs::openstack::eqiad1::web when labweb* is finished
class role::wmcs::openstack::eqiad1::labweb {
    system::role { $name: }

    include ::profile::base::production
    include ::profile::ldap::client::labs
    include ::profile::base::firewall

    # Currently we run both nutcracker and mcrouter.  Nutcracker is for
    #  the soon-to-be-moved wikitech/mediawiki install;
    #  Mcrouter is used by Horizon.  They share the same
    #  memcached backends.
    include ::profile::openstack::eqiad1::nutcracker
    include ::profile::openstack::eqiad1::cloudweb_mcrouter

    include ::profile::lvs::realserver

    # Wikitech:
    include ::profile::openstack::eqiad1::wikitech::web
    include ::profile::openstack::eqiad1::wikitech::monitor

    # Horizon:
    include ::profile::openstack::eqiad1::horizon::dashboard_source_deploy

    # Striker:
    include ::profile::wmcs::striker::docker

    include ::profile::tlsproxy::envoy # TLS termination
}
