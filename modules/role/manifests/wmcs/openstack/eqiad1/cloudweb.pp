class role::wmcs::openstack::eqiad1::cloudweb {
    include profile::base::production
    include profile::ldap::client::utils
    include profile::firewall
    include profile::base::cloud_production

    include profile::openstack::eqiad1::cloudweb_mcrouter
    include profile::lvs::realserver
    include profile::lvs::realserver::ipip

    # Horizon:
    include profile::openstack::eqiad1::horizon::docker_deploy

    # Striker:
    include profile::wmcs::striker::docker
    include profile::tlsproxy::envoy # TLS termination
}
