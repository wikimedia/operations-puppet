class role::wmcs::openstack::eqiad1::cloudweb {
    system::role { $name: }

    include ::profile::base::production
    include ::profile::ldap::client::utils
    include ::profile::firewall
    include profile::base::cloud_production

    # Currently we run both nutcracker and mcrouter.  Nutcracker is for
    #  the soon-to-be-moved wikitech/mediawiki install;
    #  Mcrouter is used by Horizon.  They share the same
    #  memcached backends.
    include ::profile::openstack::eqiad1::cloudweb_mcrouter
    include ::profile::lvs::realserver

    # Horizon:
    include ::profile::openstack::eqiad1::horizon::docker_deploy

    # Striker:
    include ::profile::wmcs::striker::docker
    include ::profile::tlsproxy::envoy # TLS termination
}
