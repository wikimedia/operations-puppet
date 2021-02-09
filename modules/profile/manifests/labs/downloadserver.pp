# Simple file server for the 'download' project
#
# filtertags: labs-project-download
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
