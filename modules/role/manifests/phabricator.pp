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
}
