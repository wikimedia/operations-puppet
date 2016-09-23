# == Class role::ci::castor::server
#
# rsync server to store cache related material from CI jobs.
class role::ci::castor::server {
    requires_realm( 'labs' )

    require role::ci::slave::labs::common

    include rsync::server

    file { '/srv/jenkins-workspace/caches':
        ensure  => directory,
        owner   => 'jenkins-deploy',
        group   => 'wikidev',
        mode    => '0775',
        require => Mount['/srv'],
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
}
