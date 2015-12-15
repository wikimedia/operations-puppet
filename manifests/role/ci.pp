# vim: set et ts=4 sw=4:

# role::ci::master
#
# Setup a Jenkins installation attended to be used as a master. This setup some
# CI specific requirements such as having workspace on a SSD device and Jenkins
# monitoring.
#
# CI test server as per T79623
class role::ci::master {

    system::role { 'role::ci::master': description => 'CI Jenkins master' }

    # We require the CI website to be on the same box as the master
    # as of July 2013.  So make sure the website has been included on the node.
    Class['role::ci::master'] -> Class['role::ci::website']

    # Load the Jenkins module, that setup a Jenkins master
    include ::jenkins,
        contint::proxy_jenkins

    # .gitconfig file required for rare git write operations
    git::userconfig { '.gitconfig for jenkins user':
        homedir  => '/var/lib/jenkins',
        settings => {
            'user' => {
                'name'  => 'Wikimedia Jenkins Bot',
                'email' => 'jenkins@gallium.wikimedia.org',
            },  # end of [user] section
            'core' => {
                # T58717: avoid eating all RAM when repacking
                'packedGitLimit' => '2G',
            },  # end of [core] section
        },  # end of settings
        require  => User['jenkins'],
    }

    # Templates for Jenkins plugin Email-ext.  The templates are hosted in
    # the repository integration/jenkins.git, so link to there.
    file { '/var/lib/jenkins/email-templates':
        ensure => link,
        target => '/srv/deployment/integration/slave-scripts/tools/email-templates',
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
    }

    # As of October 2013, the slave scripts are installed with
    # contint::slave_scripts and land under /srv/jenkins.
    # FIXME: clean up Jenkins jobs to no more refer to the paths below:
    file { '/var/lib/jenkins/.git':
        ensure => directory,
        mode   => '2775',  # group sticky bit
        group  => 'jenkins',
    }

    file { '/var/lib/jenkins/bin':
        ensure => directory,
        owner  => 'jenkins',
        group  => 'wikidev',
        mode   => '0775';
    }

    file { '/srv/ssd/jenkins':
        ensure  => 'directory',
        owner   => 'jenkins',
        group   => 'jenkins',
        mode    => '2775',  # group sticky bit
        # Mount is handled on the node definition
        require => Mount['/srv/ssd'],
    }

    # Master does not run job anymore since June 2013. But better safe than
    # sorry.  We might have to run some jobs there.
    file { '/srv/ssd/jenkins/workspace':
        ensure  => 'directory',
        owner   => 'jenkins',
        group   => 'jenkins',
        mode    => '0775',
        require => [
            File['/srv/ssd/jenkins'],
        ],
    }

    # Ganglia monitoring for Jenkins
    # The upstream module is named 'jenkins' which conflicts with python-jenkins
    # since gmond will lookup the 'jenkins' python module in the system path
    # before the module path.
    # See: https://github.com/ganglia/monitor-core/issues/111

    file { '/usr/lib/ganglia/python_modules/jenkins.py':
        ensure => absent,
    }

    file { '/etc/ganglia/conf.d/jenkins.pyconf':
        ensure => absent,
    }

    ganglia::plugin::python { 'gmond_jenkins': }

    # key pair for VE sync tasks (T84731)
    file { '/var/lib/jenkins/.ssh/jenkins-mwext-sync_id_rsa':
        ensure  => present,
        owner   => 'jenkins',
        group   => 'jenkins',
        mode    => '0400',
        content => secret('ssh/ci/jenkins-mwext-sync_id_rsa'),
        require => User['jenkins'],
    }

    file { '/var/lib/jenkins/.ssh/jenkins-mwext-sync_id_rsa.pub':
        ensure  => present,
        owner   => 'jenkins',
        group   => 'jenkins',
        mode    => '0400',
        source  => 'puppet:///modules/jenkins/jenkins-mwext-sync_id_rsa.pub',
        require => User['jenkins'],
    }

    # backups
    include role::backup::host
    backup::set {'var-lib-jenkins-config': }

}

# Set up a Jenkins slave suitable for Continuous Integration jobs execution.
class role::ci::slave {

    system::role { 'role::ci::slave': description => 'CI slave runner' }

    include contint::packages
    include role::zuul::install

    package {
        [
            'integration/mediawiki-tools-codesniffer',
            'integration/phpunit',
            'integration/phpcs',
            'integration/php-coveralls',
            'integration/slave-scripts',
        ]:
        provider => 'trebuchet',
    }

    class { 'jenkins::slave':
        ssh_key => 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA4QGc1Zs/S4s7znEYw7RifTuZ4y4iYvXl5jp5tJA9kGUGzzfL0dc4ZEEhpu+4C/TixZJXqv0N6yke67cM8hfdXnLOVJc4n/Z02uYHQpRDeLAJUAlGlbGZNvzsOLw39dGF0u3YmwDm6rj85RSvGqz8ExbvrneCVJSaYlIRvOEKw0e0FYs8Yc7aqFRV60M6fGzWVaC3lQjSnEFMNGdSiLp3Vl/GB4GgvRJpbNENRrTS3Te9BPtPAGhJVPliTflVYvULCjYVtPEbvabkW+vZznlcVHAZJVTTgmqpDZEHqp4bzyO8rBNhMc7BjUVyNVNC5FCk+D2LagmIriYxjirXDNrWlw== jenkins@gallium from="208.80.154.135"',
        user    => 'jenkins-slave',
        workdir => '/srv/ssd/jenkins-slave',
        # Mount is handled on the node definition
        require => Mount['/srv/ssd'],
    }

    # .gitconfig file required for rare git write operations
    git::userconfig { '.gitconfig for jenkins-slave user':
        homedir  => '/var/lib/jenkins-slave',
        settings => {
            'user' => {
                'name'  => 'Wikimedia Jenkins Bot',
                'email' => "jenkins-slave@${::fqdn}",
            },  # end of [user] section
        },  # end of settings
        require  => User['jenkins-slave'],
    }

    # Maven requires a webproxy on production slaves
    class { 'contint::maven_webproxy':
        homedir => '/var/lib/jenkins-slave',
        owner   => 'jenkins-slave',
        group   => 'jenkins-slave',
    }

    contint::tmpfs { 'tmpfs for jenkins CI slave':
        mount_point => '/var/lib/jenkins-slave/tmpfs',
        size        => '512M',
    }
    nrpe::monitor_service { 'ci_tmpfs':
        description  => 'CI tmpfs disk space',
        nrpe_command => '/usr/lib/nagios/plugins/check_disk -w 20% -c 5% -e -p /var/lib/jenkins-slave/tmpfs',
    }

    # user and private key for Travis integration
    # RT: 8866
    user { 'npmtravis':
        home       => '/home/npmtravis',
        managehome => true,
        system     => true,
    }

    file { '/home/npmtravis/.ssh':
        ensure  => directory,
        owner   => 'npmtravis',
        mode    => '0500',
        require => User['npmtravis'],
    }

    file { '/home/npmtravis/.ssh/npmtravis_id_rsa':
        ensure  => present,
        owner   => 'npmtravis',
        mode    => '0400',
        content => secret('ssh/ci/npmtravis_id_rsa'),
        require => File['/home/npmtravis/.ssh'],
    }

    file { '/srv/localhost-worker':
        ensure => directory,
        mode   => '0775',
        owner  => 'jenkins-slave',
        group  => 'jenkins-slave',
    }
    include contint::worker_localhost

    # Ganglia diskstat plugin is being evaluated on contint production slaves
    # servers merely to evaluate it for the standard role. -- hashar, 23-Oct-2013
    ganglia::plugin::python { 'diskstat': }
}

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

class role::ci::slave::localbrowser {
    requires_realm('labs')

    system::role { 'role::ci::slave::localbrowser':
        description => 'CI Jenkins slave for running tests in local browsers',
    }

    include role::ci::slave::labs::common
    include role::zuul::install
    include contint::browsers
}

class role::ci::slave::browsertests {
    requires_realm('labs')

    system::role { 'role::ci::slave::browsertests':
        description => 'CI Jenkins slave for browser tests',
    }

    include role::ci::slave::labs::common
    include role::zuul::install
    include contint::browsertests

    # For CirrusSearch testing:
    file { '/mnt/elasticsearch':
        ensure => absent,
    }
    file { '/var/lib/elasticsearch':
        ensure  => absent,
    }

    # For CirrusSearch testing:
    redis::instance { 6379:
        settings => {
            bind                      => '0.0.0.0',
            appendonly                => true,
            dir                       => '/mnt/redis',
            maxmemory                 => '128Mb',
            requirepass               => 'notsecure',
            auto_aof_rewrite_min_size => '32mb',
        },
    }
}

class role::ci::slave::labs {
    requires_realm('labs')

    system::role { 'role::ci::slave::labs':
        description => 'CI Jenkins slave on labs' }

    # Debian slaves are used to build Debian packages for all our distributions
    if os_version('debian >= jessie') {
        system::role { '::package_builder':
            description => 'CI package building',
        }
        class { '::package_builder':
            # We need /var/cache/pbuilder to be a symlink to /mnt
            # before cowbuilder/pbuilder is installed
            require => Class['contint::packages::labs'],
        }
    }

    file { '/srv/localhost-worker':
        ensure => directory,
        mode   => '0775',
        owner  => 'jenkins-deploy',
        group  => 'root',
    }
    include contint::worker_localhost

    contint::tmpfs { 'tmpfs for jenkins CI labs slave':
        # Jobs expect the tmpfs to be in $HOME/tmpfs
        mount_point => '/mnt/home/jenkins-deploy/tmpfs',
        size        => '512M',
        require     => File['/mnt/home/jenkins-deploy'],
    }

    # Trebuchet replacement on labs
    include contint::slave_scripts

    # Include package unsafe for production
    include contint::packages::labs

    if os_version('ubuntu >= trusty') {
        include contint::hhvm
    }

    include role::ci::slave::labs::common
    include role::zuul::install

    include role::ci::slave::localbrowser

    class { 'role::ci::slave::browsertests':
        require => [
            Class['role::ci::slave::labs::common'], # /mnt
            Class['contint::packages::labs'], # realize common packages first
        ]
    }

}

# == Class role::ci::slave::labs::light
#
# Transient role that setup a slave labs for Jessie.  Regular slaves include
# mediawiki::packages and over cmaterials which are not yet ready on Jessie
# (tracking task is https://phabricator.wikimedia.org/T94836).
#
# Let us migrate some jobs to Jessie since production is moving toward it.
#
class role::ci::slave::labs::light {

    requires_realm('labs')

    system::role { 'role::ci::slave::labs::light':
        description => 'CI *LIGHT* Jenkins slave on labs' }

    # Trebuchet replacement on labs
    include contint::slave_scripts
    include role::ci::slave::labs::common

    include contint::packages::apt
    include contint::packages::ops
    include contint::packages::python

}

# == Class role::ci::publisher::labs
#
# Intermediary rsync hosts in labs to let Jenkins slave publish their results
# safely.  The production machine hosting doc.wikimedia.org can then fetch the
# doc from there.
class role::ci::publisher::labs {

    include role::labs::lvm::srv
    include rsync::server

    file { '/srv/doc':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0775',
        require => Class['role::labs::lvm::srv'],
    }

    rsync::server::module { 'doc':
        path      => '/srv/doc',
        read_only => 'no',
        require   => [
            File['/srv/doc'],
            Class['role::labs::lvm::srv'],
        ],
    }

}

# Website for Continuous integration
#
# http://doc.mediawiki.org/
# http://doc.wikimedia.org/
# http://integration.mediawiki.org/
# http://integration.wikimedia.org/
class role::ci::website {

    system::role { 'role::ci::website': description => 'CI Websites' }

    include role::zuul::configuration

    class { 'contint::website':
        zuul_git_dir => $role::zuul::configuration::zuul_git_dir,
    }
}

# Grants genkins access to instances this is applied on
# Also turns them into a jenkins slave
# Used mostly for *oids atm.
class role::ci::jenkins_access {
    # Allow ssh access from the Jenkins master to the server where citoid is
    # running
    include contint::firewall::labs

    # Instance got to be a Jenkins slave so we can update citoid whenever a
    # change is made on mediawiki/services/citoid repository
    include role::ci::slave::labs::common
    # Also need the slave scripts for multi-git.sh
    include contint::slave_scripts
}
