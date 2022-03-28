# == Class role::ci::castor::server
#
# rsync server to store cache related material from CI jobs.
#
class profile::ci::castor::server {

    class { 'rsync::server':
        # Disable DNS lookup, they are only needed for host allow/deny which we
        # do not use. That might cause log spam as well: T136276
        rsyncd_conf => {
            'forward lookup' => 'no',
        }
    }

    rsync::server::module { 'caches':
        path      => '/srv/jenkins-workspace/caches',
        read_only => 'yes',
        uid       => 'jenkins-deploy',
        gid       => 'wikidev',
        require   => [
            File['/srv/jenkins-workspace/caches'],
        ],
    }

    file { '/srv/jenkins-workspace/caches':
        ensure => directory,
        owner  => 'jenkins-deploy',
        group  => 'wikidev',
        mode   => '0775',
    }
}
