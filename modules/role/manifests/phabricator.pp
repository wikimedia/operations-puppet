# phabricator instance
#
class role::phabricator {
    include profile::base::production
    include profile::firewall
    include profile::backup::host
    include profile::phabricator::main
    include profile::phabricator::logmail
    include profile::phabricator::httpd
    include profile::phabricator::monitoring
    include profile::phabricator::performance
    include profile::phabricator::datasync
    include profile::prometheus::apache_exporter
    include profile::tlsproxy::envoy # TLS termination
    include rsync::server # copy repo data between servers
}
