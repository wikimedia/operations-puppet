# SPDX-License-Identifier: Apache-2.0
# Role for the MediaWiki memcached wikifunctions cluster role for production.
class role::mediawiki::memcached::wikifunctions {
    include profile::base::production
    include profile::firewall
    include profile::memcached::instance
    include profile::memcached::memkeys
    include profile::memcached::performance
}
