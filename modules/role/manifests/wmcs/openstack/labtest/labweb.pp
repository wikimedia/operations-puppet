# All horizon/striker/wikitech profiles should fold into
# role::wmcs::openstack::labtest::web when labweb* is finished
class role::wmcs::openstack::labtest::labweb {
    system::role { $name: }

    include ::profile::ldap::client::labs
    include ::profile::base::firewall
    include ::profile::openstack::labtest::nutcracker

    # Wikitech:
    include ::profile::openstack::labtest::wikitech::web
    include ::profile::openstack::labtest::wikitech::monitor

    # Horizon:
    include ::profile::openstack::labtest::horizon::dashboard_source_deploy

    # Striker:
    include ::profile::wmcs::striker::web
}
