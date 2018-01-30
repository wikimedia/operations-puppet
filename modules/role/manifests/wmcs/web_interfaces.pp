# web interfaces for wmcs admins
# Horizon + Wikitech + Striker
class role::wmcs::web_interfaces {

    include ::standard
    include ::profile::base::firewall
    include ::role::wmcs::openstack::main::horizon
    include ::role::striker::web
    include ::profile::ldap::client::labs

    class { '::httpd':
        modules => ['alias', 'ssl', 'php5', 'rewrite', 'headers', 'wsgi', 'expires', 'lbmethod_byrequests', 'proxy', 'proxy_balancer', 'proxy_http'],
    }
}
