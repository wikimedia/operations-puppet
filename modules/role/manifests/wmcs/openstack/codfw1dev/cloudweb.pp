# All horizon/striker/wikitech profiles should fold into
# role::wmcs::openstack::codfw1dev::web when labweb* is finished
class role::wmcs::openstack::codfw1dev::cloudweb {
    include profile::base::production
    include profile::ldap::client::utils
    include profile::firewall
    include profile::base::cloud_production

    include profile::openstack::codfw1dev::cloudweb_mcrouter

    # Horizon:
    include profile::openstack::codfw1dev::horizon::docker_deploy

    # TLS termination
    include profile::tlsproxy::envoy

    # LDAP tools
    include profile::ldap::client::ldaptui
}
