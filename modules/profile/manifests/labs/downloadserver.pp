# Simple file server for the 'download' project
#
# filtertags: labs-project-download
class profile::labs::downloadserver {
    labs_lvm::volume { 'srv':
        mountat => '/srv',
    }

    file { '/srv/public_files':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => Labs_lvm::Volume['srv'],
    }

    nginx::site { 'downloadserver':
        source  => 'puppet:///modules/profile/labs/downloadserver.nginx',
        require => Labs_lvm::Volume['srv'],
    }
}
