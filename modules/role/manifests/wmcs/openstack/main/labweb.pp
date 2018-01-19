# All horizon/striker/wikitech profiles should fold into
# role::wmcs::openstack::main::web when labweb* is finished
class role::wmcs::openstack::main::labweb {
    system::role { $name: }

    class { '::httpd':
        modules => ['alias', 'ssl', 'php5', 'rewrite', 'headers'],
    }

    include ::ldap::role::client::labs

    # Wikitech:
    include ::role::mediawiki::webserver
    include ::profile::base::firewall
    include ::profile::prometheus::apache_exporter
    include ::profile::prometheus::hhvm_exporter

    # Horizon:
    include ::profile::openstack::base::horizon::dashboard_source_deploy

    # Striker: 
    ## (this profile not yet written)
}
