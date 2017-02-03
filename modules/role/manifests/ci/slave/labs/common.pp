# Common configuration to be applied on any labs Jenkins slave
#
# filtertags: labs-project-deployment-prep labs-project-git labs-project-ci-staging
class role::ci::slave::labs::common {

    # Jenkins slaves need to access beta cluster for the browsertests
    include contint::firewall::labs
    include contint::packages::base

    # Need the labs instance extended disk space
    require role::labs::lvm::mnt

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

    # drop settings file with old proxy settings
    file { '/mnt/home/jenkins-deploy/.m2/settings.xml':
        ensure => absent
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
