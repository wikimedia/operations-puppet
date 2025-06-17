# SPDX-License-Identifier: Apache-2.0
# temp allow rsyncing phabricator data to new servers
class role::phabricator::migration {
    include profile::base::production
    include profile::firewall
    include profile::phabricator::migration
    include profile::phabricator::httpd
}
