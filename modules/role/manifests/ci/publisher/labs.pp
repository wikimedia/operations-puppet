# == Class role::ci::publisher::labs
#
# Intermediary rsync hosts in labs to let Jenkins slave publish their results
# safely.  The production machine hosting doc.wikimedia.org can then fetch the
# doc from there.
class role::ci::publisher::labs {

    include role::labs::lvm::srv
    include rsync::server

    file { '/srv/doc':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0775',
        require => Class['role::labs::lvm::srv'],
    }

    rsync::server::module { 'doc':
        path      => '/srv/doc',
        read_only => 'no',
        require   => [
            File['/srv/doc'],
            Class['role::labs::lvm::srv'],
        ],
    }

}

