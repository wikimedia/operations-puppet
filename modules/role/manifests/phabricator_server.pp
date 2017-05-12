# phabricator instance
#
# filtertags: labs-project-deployment-prep labs-project-phabricator
class role::phabricator_server {

    system::role { 'role::phabricator_server':
        description => 'Phabricator (Main) Server'
    }

    include ::standard
    include ::lvs::realserver
    include ::base::firewall
    include ::apache::mod::remoteip
    include ::profile::backup::host
    include ::profile::phabricator::main
    include ::profile::phabricator::rsync
    include ::passwords::phabricator
    include ::passwords::mysql::phabricator
    include ::phabricator::monitoring
    include ::phabricator::mpm
    include ::exim4::ganglia
    include ::ganglia
}
