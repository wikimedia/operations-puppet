# Common configuration to be applied on any labs Jenkins slave
class role::ci::slave::labs::common {

    # Jenkins slaves need to access beta cluster for the browsertests
    include contint::firewall::labs
    include contint::packages::base

    if $::site == 'eqiad' {
        # Does not come with /dev/vdb, we need to mount it using lvm
        require role::labs::lvm::mnt

        # Will make sure /mnt is mounted before populating file there or they
        # might end up being being created locally and hidden by the mount.
        $slash_mnt_require = Mount['/mnt']
    } else {
        file { '/mnt':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0775',
        }
        $slash_mnt_require = File['/mnt']
    }

    # Home dir for Jenkins agent
    #
    # We will use neither /var/lib (partition too small) nor /home since it is
    # GlusterFS.
    #
    # Instead, create a work dir on /dev/vdb which has all the instance disk
    # space and is usually mounted on /mnt.
    file { '/mnt/jenkins-workspace':
        ensure  => directory,
        owner   => 'jenkins-deploy',
        group   => 'wikidev',  # useless, but we need a group
        mode    => '0775',
        require => $slash_mnt_require,
    }

    # Create a homedir for `jenkins-deploy` so it does not end up being created
    # on /home which is using GlusterFS on the integration project.  The user is
    # only LDAP and is not created by puppet
    # T63144
    file { '/mnt/home':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => $slash_mnt_require,
    }

    file { '/mnt/home/jenkins-deploy':
        ensure => directory,
        owner  => 'jenkins-deploy',
        group  => 'wikidev',
        mode   => '0775',
    }

    # Maven requires a webproxy on labs slaves
    class { 'contint::maven_webproxy':
        homedir => '/mnt/home/jenkins-deploy',
        owner   => 'jenkins-deploy',
        group   => 'wikidev',
        require => File['/mnt/home/jenkins-deploy'],
    }

    git::userconfig { '.gitconfig for jenkins-deploy user':
        homedir  => '/mnt/home/jenkins-deploy',
        settings => {
            'user' => {
                'name'  => 'Wikimedia Jenkins Deploy',
                'email' => "jenkins-deploy@${::instancename}.${::site}.wmflabs",
            },  # end of [user] section
        },  # end of settings
        require  => File['/mnt/home/jenkins-deploy'],
    }

    # The slaves on labs use the `jenkins-deploy` user which is already
    # configured in labs LDAP.  Thus, we only need to install the dependencies
    # needed by the slave agent.
    include jenkins::slave::requisites

}

