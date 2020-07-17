# aphlict for phabricator
#
class role::aphlict {

    system::role { 'aphlict':
        description => 'Notification server for Phabricator'
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::phabricator::aphlict
    # include ::profile::tlsproxy::envoy # TLS termination
}
