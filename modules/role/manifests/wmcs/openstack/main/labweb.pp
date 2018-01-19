# All horizon/striker/wikitech profiles should fold into
# role::wmcs::openstack::main::web when labweb* is finished
class role::wmcs::openstack::main::labweb {
    system::role { $name: }

    include ::ldap::role::client::labs

    # Wikitech:
    include ::role::mediawiki::webserver
    include ::profile::base::firewall
    include ::profile::prometheus::apache_exporter
    include ::profile::prometheus::hhvm_exporter

    # Horizon:
    ## (this profile not yet written)

    # Striker: 
    include ::profile::striker::web
}
