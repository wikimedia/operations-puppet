# All horizon/striker/wikitech profiles should fold into
# role::wmcs::openstack::labtest::web when labweb* is finished
class role::wmcs::openstack::labtest::labweb {
    system::role { $name: }

    require_package('libapache2-mod-wsgi-py3')
    class { '::httpd':
        modules => ['alias', 'ssl', 'rewrite', 'headers', 'wsgi',
                    'proxy', 'expires', 'proxy_http', 'proxy_balancer',
                    'lbmethod_byrequests', 'proxy_fcgi'],
    }

    include ::profile::ldap::client::labs
    include ::profile::base::firewall
    include ::profile::openstack::labtest::nutcracker
    include ::role::lvs::realserver

    # Wikitech:
    include ::profile::openstack::labtest::wikitech::web
    include ::profile::openstack::labtest::wikitech::monitor

    # Horizon:
    include ::profile::openstack::labtest::horizon::dashboard_source_deploy

    # Striker:
    include ::profile::openstack::base::striker::web
}
