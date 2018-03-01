class role::wmcs::openstack::main::wikitech {
    system::role { $name: }
    include ::standard
    include ::profile::base::firewall
    include ::profile::openstack::main::cloudrepo
    include ::profile::openstack::main::clientlib
    include ::profile::openstack::main::wikitech::service

    if os_version('debian >= stretch') {
        $php_module = 'php7.0'
    } else {
        $php_module = 'php5'
    }

    class { '::httpd':
        modules => ['alias', 'ssl', $php_module, 'rewrite', 'headers'],
    }
}
