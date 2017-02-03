# == Class role::ci::castor::server
#
# rsync server to store cache related material from CI jobs.
#
# filtertags: labs-project-integration
class role::ci::castor::server {
    requires_realm( 'labs' )

    include role::labs::lvm::mnt
    include rsync::server

    file { '/mnt/jenkins-workspace/caches':
        ensure  => directory,
        owner   => 'jenkins-deploy',
        group   => 'wikidev',
        mode    => '0775',
        require => Class['role::labs::lvm::mnt'],
    }

    rsync::server::module { 'caches':
        path      => '/mnt/jenkins-workspace/caches',
        read_only => 'yes',
        uid       => 'jenkins-deploy',
        gid       => 'wikidev',
        require   => [
            File['/mnt/jenkins-workspace/caches'],
            Class['role::labs::lvm::mnt'],
        ],
    }
}
