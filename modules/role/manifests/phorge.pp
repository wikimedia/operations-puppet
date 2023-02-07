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

    ensure_packages(['libapache2-mod-php', 'git'])

    $apache_modules = ['rewrite', 'headers', 'php7.4']

    class { 'httpd::mpm':
        mpm    => 'prefork',
    }

    class { 'httpd':
        modules             => $apache_modules,
        purge_manual_config => false,
        require             => Class['httpd::mpm'],
    }

    include profile::mariadb::generic_server
    include profile::phorge
}
