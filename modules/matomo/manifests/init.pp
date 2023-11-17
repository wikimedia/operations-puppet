# SPDX-License-Identifier: Apache-2.0
# == Class: matomo
#
# Matomo (formerly Piwik) is an open-source analytics platform.
#
# https://matomo.org/
#
# Matomo's installation is meant to be executed manually using its UI,
# to initialize the database and generate the related config file.
# Therefore each new deployment from scratch will require some manual work,
# please keep it mind.
#
# Misc:
# Q: Where did the deb package come from?
# A: https://debian.piwik.org, imported to apt.wikimedia.org
#
class matomo (
    $database_host      = 'localhost',
    $database_password  = undef,
    $database_username  = 'piwik',
    $admin_username     = undef,
    $admin_password     = undef,
    $password_salt      = undef,
    $trusted_hosts      = [],
    $piwik_username     = 'www-data',
) {

    apt::package_from_component { 'matomo':
        component => 'thirdparty/matomo',
        packages  => ['matomo'],
    }

    $database_name = 'piwik'
    $database_table_prefix = 'piwik_'
    $proxy_client_headers = ['HTTP_X_FORWARDED_FOR']

    file { '/etc/matomo/config.ini.php':
        content => template('matomo/config.ini.php.erb'),
        owner   => $piwik_username,
        group   => $piwik_username,
        mode    => '0750',
        require => Package['matomo'],
    }

    # The TagManager plugin needs to have write access to a certain directory in order to be able to
    # write the container javascript snippets that it requires. We do not wish to enable write access
    # to the default location of /usr/share/matmo/js so we need to override a pair of functions to
    # specify a custom directory that is within an existing writeable location. This is gone in a custom
    # config.php file. See #T349910 and https://github.com/matomo-org/tag-manager/issues/154 for more.
    file { '/etc/matomo/config.php':
        source => 'puppet:///modules/matomo/config.php',
        mode   => '0640',
    }

    file { '/var/log/matomo':
        ensure  => 'directory',
        owner   => $piwik_username,
        group   => $piwik_username,
        mode    => '0755',
        require => Package['matomo'],
    }
}
