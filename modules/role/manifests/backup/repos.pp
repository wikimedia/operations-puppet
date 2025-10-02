# SPDX-License-Identifier: Apache-2.0
# Storage daemons for Bacula, specific to repo data (Gerrit and Gitlab).
class role::backup::repos {
    include profile::firewall
    include profile::base::production

    include profile::backup::storage::repos
}
