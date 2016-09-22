# Common configuration to be applied on any labs Jenkins slave
class role::ci::slave::labs::common {

    # Jenkins slaves need to access beta cluster for the browsertests
    include contint::firewall::labs
    include contint::packages::base

    # Need the labs instance extended disk space
    require role::labs::lvm::mnt

    # Duplicate for transition purposes
    mount { '/srv':
        ensure  => mounted,
        atboot  => true,
        device  => '/dev/vd/second-local-disk',
        options => 'defaults',
        fstype  => 'ext4',
        require => Class['role::labs::lvm::mnt'],
    }

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

    git::userconfig { '.gitconfig for jenkins-deploy user in srv':
        homedir  => '/srv/home/jenkins-deploy',
        settings => {
            'user' => {
                'name'  => 'Wikimedia Jenkins Deploy',
                'email' => "jenkins-deploy@${::fqdn}",
            },
        },
        require  => File['/srv/home/jenkins-deploy'],
    }

    ##### Legacy based on /mnt #############################

    # Home dir for Jenkins agent
    #
    # /var/lib and /home are too small to hold Jenkins workspaces
    file { '/mnt/jenkins-workspace':
        ensure  => directory,
        owner   => 'jenkins-deploy',
        group   => 'wikidev',  # useless, but we need a group
        mode    => '0775',
        require => Mount['/mnt'],
    }

    # Create a homedir for `jenkins-deploy` so we get plenty of disk space.
    # The user is only LDAP and is not created by puppet
    # T63144
    file { '/mnt/home':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Mount['/mnt'],
    }

    file { '/mnt/home/jenkins-deploy':
        ensure => directory,
        owner  => 'jenkins-deploy',
        group  => 'wikidev',
        mode   => '0775',
    }

    git::userconfig { '.gitconfig for jenkins-deploy user':
        homedir  => '/mnt/home/jenkins-deploy',
        settings => {
            'user' => {
                'name'  => 'Wikimedia Jenkins Deploy',
                'email' => "jenkins-deploy@${::fqdn}",
            },  # end of [user] section
        },  # end of settings
        require  => File['/mnt/home/jenkins-deploy'],
    }

    # The slaves on labs use the `jenkins-deploy` user which is already
    # configured in labs LDAP.  Thus, we only need to install the dependencies
    # needed by the slave agent.
    include jenkins::slave::requisites

}
