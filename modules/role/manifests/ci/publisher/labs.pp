# == Class role::ci::publisher::labs
#
# Intermediary rsync hosts in labs to let Jenkins slave publish their results
# safely.  The production machine hosting doc.wikimedia.org can then fetch the
# doc from there.
#
# filtertags: labs-project-integration
class role::ci::publisher::labs {

    require ::profile::labs::lvm::srv
    include rsync::server

    file { '/srv/doc':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0775',
    }

    rsync::server::module { 'doc':
        path      => '/srv/doc',
        read_only => 'no',
        require   => [
            File['/srv/doc'],
        ],
    }

}

