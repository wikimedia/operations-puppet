# Common configuration to be applied on any labs Jenkins slave
#
# filtertags: labs-project-deployment-prep labs-project-git
class role::ci::slave::labs::common {

    # Need the labs instance extended disk space
    require ::profile::labs::lvm::srv

    # Jenkins slaves need to access beta cluster for the browsertests
    include contint::firewall::labs

    # New file layout based on /srv

    # base directory
    file { '/srv/jenkins':
        ensure  => directory,
        owner   => 'jenkins-deploy',
        group   => 'wikidev',
        mode    => '0775',
        require => Mount['/srv'],
    }

    file { '/srv/jenkins/cache':
        ensure  => directory,
        owner   => 'jenkins-deploy',
        group   => 'wikidev',
        mode    => '0775',
        require => File['/srv/jenkins'],
    }

    file { '/srv/jenkins/workspace':
        ensure  => directory,
        owner   => 'jenkins-deploy',
        group   => 'wikidev',
        mode    => '0775',
        require => File['/srv/jenkins'],
    }

    # Legacy from /mnt era
    file { '/srv/jenkins-workspace':
        ensure  => directory,
        owner   => 'jenkins-deploy',
        group   => 'wikidev',  # useless, but we need a group
        mode    => '0775',
        require => Mount['/srv'],
    }

    file { '/srv/home':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Mount['/srv'],
    }
    file { '/srv/home/jenkins-deploy':
        ensure  => directory,
        owner   => 'jenkins-deploy',
        group   => 'wikidev',
        mode    => '0775',
        require => File['/srv/home'],
    }

    git::userconfig { '.gitconfig for jenkins-deploy user':
        homedir  => '/srv/home/jenkins-deploy',
        settings => {
            'user' => {
                'name'  => 'Wikimedia Jenkins Deploy',
                'email' => "jenkins-deploy@${::fqdn}",
            },
        },
        require  => File['/srv/home/jenkins-deploy'],
    }

    # The slaves on labs use the `jenkins-deploy` user which is already
    # configured in labs LDAP.  Thus, we only need to install the dependencies
    # needed by the slave agent, eg the java jre.
    include jenkins::common

}
