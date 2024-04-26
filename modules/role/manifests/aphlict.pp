# aphlict for phabricator
#
class role::aphlict {
    include profile::base::production
    include profile::firewall
    include profile::phabricator::aphlict
    include profile::tlsproxy::envoy # TLS termination
}
