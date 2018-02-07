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
    include ::apache::mod::remoteip
    include ::profile::backup::host
    include ::profile::phabricator::main
    include ::phabricator::monitoring
    include ::phabricator::mpm

    if os_version('debian >= stretch') {
        $php_module = 'php7'
    } else {
        $php_module = 'php5'
    }

    class { '::httpd':
        modules => [status, $php_module],
    }
}
