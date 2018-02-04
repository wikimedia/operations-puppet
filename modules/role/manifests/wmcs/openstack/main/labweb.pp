# All horizon/striker/wikitech profiles should fold into
# role::wmcs::openstack::main::web when labweb* is finished
class role::wmcs::openstack::main::labweb {
    system::role { $name: }

    require_package('libapache2-mod-wsgi-py3')
    class { '::httpd':
        modules => ['alias', 'ssl', 'rewrite', 'headers', 'wsgi'],
    }

    include ::profile::ldap::client::labs

    # Wikitech:
    #include ::role::mediawiki::webserver
    #include ::profile::base::firewall
    #include ::profile::prometheus::apache_exporter
    #include ::profile::prometheus::hhvm_exporter

    # Horizon:
    include ::profile::openstack::main::horizon::dashboard_source_deploy

    # Striker:
    ## (this profile not yet written)
}
