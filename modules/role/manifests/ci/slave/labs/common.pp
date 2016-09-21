# Common configuration to be applied on any labs Jenkins slave
class role::ci::slave::labs::common {

    # Jenkins slaves need to access beta cluster for the browsertests
    include contint::firewall::labs
    include contint::packages::base

    # Need the labs instance extended disk space
    require role::labs::lvm::srv

    # We no more use role::labs::lvm::mnt
    mount { '/mnt':
        ensure => absent,
    }

    file { '/srv/jenkins':
        ensure  => directory,
        owner   => 'jenkins-deploy',
        group   => 'wikidev',  # useless, but we need a group
        mode    => '0775',
        require => Mount['/srv'],
    }

    # Home dir for Jenkins agent
    #
    # /var/lib and /home are too small to hold Jenkins workspaces
    file { '/srv/jenkins/workspace':
        ensure  => directory,
        owner   => 'jenkins-deploy',
        group   => 'wikidev',  # useless, but we need a group
        mode    => '0775',
        require => File['/srv/jenkins'],
    }

    # Create a homedir for `jenkins-deploy` so we get plenty of disk space.
    # The user is only LDAP and is not created by puppet. LDAP has the homedir
    # set to /mnt/home/jenkins-deploy for legacy reason.
    # T63144
    file { '/mnt/home':
        ensure  => directory,
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        require => Mount['/mnt'],  # ensure => absent
    }

    file { '/mnt/home/jenkins-deploy':
        ensure  => link,
        target  => '/srv/jenkins/home/jenkins-deploy',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        require => [
            Mount['/mnt'],  # ensure => absent
            File['/mnt/home'],
        ],
    }

    file { '/srv/jenkins/home':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => File['/srv/jenkins'],
    }

    file { '/srv/jenkins/home/jenkins-deploy':
        ensure  => directory,
        owner   => 'jenkins-deploy',
        group   => 'wikidev',
        mode    => '0775',
        require => File['/srv/jenkins/home'],
    }

    git::userconfig { '.gitconfig for jenkins-deploy user':
        homedir  => '/srv/jenkins/home/jenkins-deploy',
        settings => {
            'user' => {
                'name'  => 'Wikimedia Jenkins Deploy',
                'email' => "jenkins-deploy@${::fqdn}",
            },  # end of [user] section
        },  # end of settings
        require  => File['/srv/jenkins/home/jenkins-deploy'],
    }

    # The slaves on labs use the `jenkins-deploy` user which is already
    # configured in labs LDAP.  Thus, we only need to install the dependencies
    # needed by the slave agent.
    include jenkins::slave::requisites

}
