# phabricator instance
#
# filtertags: labs-project-deployment-prep labs-project-phabricator
class role::phabricator {

    system::role { 'phabricator':
        description => 'Phabricator (Main) Server'
    }

    include ::standard
    include ::lvs::realserver
    include ::profile::base::firewall
    include ::profile::backup::host
    include ::profile::phabricator::main
    include ::phabricator::monitoring
    include ::phabricator::mpm
    include ::profile::prometheus::apache_exporter

    if os_version('debian >= stretch') {
        $php_module = 'php71'
    } else {
        $php_module = 'php5'
    }

    class { '::httpd':
        modules => ['headers', 'rewrite', 'remoteip', $php_module],
    }
}
