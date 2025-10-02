# SPDX-License-Identifier: Apache-2.0
# Profile class for adding a storage daemon service,
# specifically, for code repository data such as Gerrit and Gitlab.

class profile::backup::storage::repos {
    include profile::backup::storage::common

    file { '/srv/bacula':
        ensure => directory,
        owner  => 'bacula',
        group  => 'bacula',
        mode   => '0660',
    }

    $upcase_site = capitalize($::site)
    bacula::storage::device { "FileStorageRepos${upcase_site}":
        device_type     => 'File',
        media_type      => 'File',
        archive_device  => '/srv/bacula',
        max_concur_jobs => 2,
    }
}
