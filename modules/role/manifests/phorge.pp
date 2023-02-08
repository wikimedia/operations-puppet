# SPDX-License-Identifier: Apache-2.0
# = class: role::phorge
#
# Sets up a simple LAMP server
# and then git clones phorge,
# the community fork of Phabricator
#
class role::phorge {

    system::role { 'phorge':
        ensure      => 'present',
        description => 'httpd, PHP, mariadb, phorge',
    }

    include profile::mariadb::generic_server
    include profile::phorge
}
