# == Class: profile::piwik::instance
#
# Configuration options for piwik.wikimedia.org
#
class profile::piwik::instance (
    $trusted_hosts = ['piwik.wikimedia.org', 'wikimediafoundation.org'],
) {
    class { 'piwik': }
}