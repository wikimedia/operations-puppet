# SPDX-License-Identifier: Apache-2.0
define backup::openldapset () {
    file { '/etc/bacula/scripts/openldap-pre':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0500',
        source => 'puppet:///modules/backup/openldap-pre',
    }

    file { '/etc/bacula/scripts/openldap-post':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0500',
        source => 'puppet:///modules/backup/openldap-post',
    }

    $run_scripts = {
        'ClientRunBeforeJob' => '/etc/bacula/scripts/openldap-pre',
        'ClientRunAfterJob' => '/etc/bacula/scripts/openldap-post',
    }
    backup::set { $title:
        extras      => $run_scripts,
    }
}
