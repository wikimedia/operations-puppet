class role::wmcs::openstack::labtest::web {
    system::role { $name: }
    include ::standard
    include ::profile::base::firewall
    include ::profile::openstack::labtest::cloudrepo
    include ::profile::openstack::labtest::clientlib
    include ::profile::openstack::labtest::observerenv
    include ::profile::openstack::labtest::wikitech::service
    include ::profile::openstack::labtest::horizon::dashboard
    include ::profile::ldap::client::labs

    if os_version('debian >= stretch') {
        $php_module = 'php7.0'
    } else {
       $php_module = 'php5'
    }

    class { '::httpd':
        modules => ['alias', 'ssl', $php_module, 'rewrite', 'headers'],
    }
}
