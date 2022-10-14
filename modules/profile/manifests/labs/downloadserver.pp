# SPDX-License-Identifier: Apache-2.0
# Simple file server for the 'download' project
#
class profile::labs::downloadserver {
    file { '/srv/public_files':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    nginx::site { 'downloadserver':
        source  => 'puppet:///modules/profile/labs/downloadserver.nginx',
    }
}
