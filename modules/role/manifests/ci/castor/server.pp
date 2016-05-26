# == Class role::ci::castor::server
#
# rsync server to store cache related material from CI jobs.
#
# filtertags: labs-project-integration
class role::ci::castor::server {
    requires_realm( 'labs' )

    include role::labs::lvm::mnt
    class { 'rsync::server':
        # Disable DNS lookup since wmflabs fails to set some for contintcloud
        # and that is annoying in logs. That is solely needed for host
        # allow/deny which we do not use. T136276
        rsyncd_conf => {
            'forward lookup' => 'no',
        }
    }

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
