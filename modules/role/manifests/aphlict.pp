# aphlict for phabricator
#
class role::aphlict {

    system::role { 'aphlict':
        description => 'Notification server for Phabricator'
    }

    include ::profile::base::production
    include ::profile::firewall
    include ::profile::phabricator::aphlict
    include ::profile::tlsproxy::envoy # TLS termination
}
