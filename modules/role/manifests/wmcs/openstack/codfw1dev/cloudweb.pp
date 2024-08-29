# All horizon/striker/wikitech profiles should fold into
# role::wmcs::openstack::codfw1dev::web when labweb* is finished
class role::wmcs::openstack::codfw1dev::cloudweb {
    include profile::base::production
    include profile::ldap::client::utils
    include profile::firewall
    include profile::base::cloud_production

    # Currently we run both nutcracker and mcrouter.  Nutcracker is for
    #  the soon-to-be-moved wikitech/mediawiki install;
    #  Mcrouter is used by Horizon.  They share the same
    #  memcached backends.
    include profile::openstack::codfw1dev::nutcracker
    include profile::openstack::codfw1dev::cloudweb_mcrouter

    # Wikitech:
    include profile::openstack::codfw1dev::wikitech::web

    # Horizon:
    include profile::openstack::codfw1dev::horizon::docker_deploy

    # TLS termination
    include profile::tlsproxy::envoy

    # CAS / IDP
    include profile::idp
    include profile::java
}
