# vim: set et ts=4 sw=4:

# role::ci::master
#
# Setup a Jenkins installation attended to be used as a master. This setup some
# CI specific requirements such as having workspace on a SSD device and Jenkins
# monitoring.
#
# CI test server as per RT #1204
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
        homedir => '/var/lib/jenkins',
        settings => {
            'user' => {
                'name'  => 'Wikimedia Jenkins Bot',
                'email' => 'jenkins@gallium.wikimedia.org',
            },  # end of [user] section
            'core' => {
                # bug 56717: avoid eating all RAM when repacking
                'packedGitLimit' => '2G',
            },  # end of [core] section
        },  # end of settings
        require => User['jenkins'],
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
    # contint::slave-scripts and land under /srv/jenkins.
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
    file { '/usr/lib/ganglia/python_modules/gmond_jenkins.py':
        source => 'puppet:///files/ganglia/plugins/jenkins.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Service['gmond'],
    }

    file { '/etc/ganglia/conf.d/jenkins.pyconf':
        ensure => absent,
    }
    file { '/etc/ganglia/conf.d/gmond_jenkins.pyconf':
        source => 'puppet:///files/ganglia/plugins/jenkins.pyconf',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Service['gmond'],
    }
}

# Set up a Jenkins slave suitable for Continuous Integration jobs execution.
# You will need to setup the Gerrit replication on the Gerrit server by
# amending the role::gerrit::production class
class role::ci::slave {

    system::role { 'role::ci::slave': description => 'CI slave runner' }

    include contint::packages
    include contint::qunit_localhost
    include role::gerrit::production::replicationdest
    include role::zuul::install

    deployment::target { 'contint-production-slaves': }

    class { 'jenkins::slave':
        ssh_authorized_key => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA4QGc1Zs/S4s7znEYw7RifTuZ4y4iYvXl5jp5tJA9kGUGzzfL0dc4ZEEhpu+4C/TixZJXqv0N6yke67cM8hfdXnLOVJc4n/Z02uYHQpRDeLAJUAlGlbGZNvzsOLw39dGF0u3YmwDm6rj85RSvGqz8ExbvrneCVJSaYlIRvOEKw0e0FYs8Yc7aqFRV60M6fGzWVaC3lQjSnEFMNGdSiLp3Vl/GB4GgvRJpbNENRrTS3Te9BPtPAGhJVPliTflVYvULCjYVtPEbvabkW+vZznlcVHAZJVTTgmqpDZEHqp4bzyO8rBNhMc7BjUVyNVNC5FCk+D2LagmIriYxjirXDNrWlw==',
        ssh_key_name       => 'jenkins@gallium',
        # Lamely restrict to master which is gallium
        ssh_key_options    => [ 'from="208.80.154.135"' ],
        user               => 'jenkins-slave',
        workdir            => '/srv/ssd/jenkins-slave',
        # Mount is handled on the node definition
        require            => Mount['/srv/ssd'],
    }

    # .gitconfig file required for rare git write operations
    git::userconfig { '.gitconfig for jenkins-slave user':
        homedir => '/var/lib/jenkins-slave',
        settings => {
            'user' => {
                'name'  => 'Wikimedia Jenkins Bot',
                'email' => "jenkins-slave@${::fqdn}",
            },  # end of [user] section
        },  # end of settings
        require => User['jenkins-slave'],
    }

    # Maven requires a webproxy on production slaves
    class { 'contint::maven_webproxy':
        homedir => '/var/lib/jenkins-slave',
        owner   => 'jenkins-slave',
        group   => 'jenkins-slave',
    }

    contint::tmpfs { 'tmpfs for jenkins CI slave':
        user        => 'jenkins-slave',
        group       => 'jenkins-slave',
        mount_point => '/var/lib/jenkins-slave/tmpfs',
        size        => '512M',
    }
    nrpe::monitor_service { 'ci_tmpfs':
        description  => 'CI tmpfs disk space',
        nrpe_command => '/usr/lib/nagios/plugins/check_disk -w 20% -c 5% -e -p /var/lib/jenkins-slave/tmpfs',
    }

    # Setup Gerrit replication destination:
    file { '/srv/ssd/gerrit':
        ensure => 'directory',
        owner  => 'gerritslave',
        group  => 'root',
        mode   => '0755',
    }

    # Ganglia diskstat plugin is being evaluated on contint production slaves
    # servers merely to evaluate it for the standard role. -- hashar, 23-Oct-2013
    ganglia::plugin::python { 'diskstat': }
}

# Common configuration to be applied on any labs Jenkins slave
class role::ci::slave::labs::common {

    # Jenkins slaves need to access beta cluster for the browsertests
    include contint::firewall::labs
    include role::zuul::install

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

    # Create a homedir for `jenkins-deploy` so it does not ends up being created
    # on /home which is using GlusterFS on the integration project.  The user is
    # only LDAP and is not created by puppet
    # bug 61144
    file { '/mnt/home':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
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

    file { '/mnt/home/jenkins-deploy/.pip':
        ensure => directory,
        owner  => 'jenkins-deploy',
        group  => 'wikidev',
        mode   => '0775',
    }
    file { '/mnt/home/jenkins-deploy/.pip/pip.conf':
        ensure => present,
        owner  => 'jenkins-deploy',
        group  => 'wikidev',
        mode   => '0775',
        source => 'puppet:///modules/contint/pip-labs-slaves.conf',
    }

    git::userconfig { '.gitconfig for jenkins-deploy user':
        homedir  => '/mnt/home/jenkins-deploy',
        settings => {
            'user' => {
                'name'  => 'Wikimedia Jenkins Deploy',
                'email' => "jenkins-deploy@${::instancename}.${::site}.wmflabs",
            },  # end of [user] section
        },  # end of settings
        require => File['/mnt/home/jenkins-deploy'],
    }

    # The slaves on labs use the `jenkins-deploy` user which is already
    # configured in labs LDAP.  Thus, we only need to install the dependencies
    # needed by the slave agent.
    include jenkins::slave::requisites

}

class role::ci::slave::browsertests {

    system::role { 'role::ci::slave::browsertests':
        description => 'CI Jenkins slave for browser tests' }

    if $::realm != 'labs' {
        fail( 'role::ci::slave::browsertests must only be applied in labs' )
    }

    include role::ci::slave::labs::common

    /**
    * FIXME breaks puppet because jenkins-deploy is not known
    * by puppet since it is provided via LDAP.
    */
    /**
    contint::tmpfs { 'tmpfs for jenkins CI slave':
        user        => 'jenkins-deploy',
        group       => 'wikidev',
        # Jobs expect the tmpfs to be in $HOME/tmpfs
        mount_point => '/home/jenkins-deploy/tmpfs',
        size        => '128M',
    }
    **/

    # We are in labs context, so use /mnt (== /dev/vdb)
    # Never EVER think about using GlusterFS.
    file { '/mnt/localhost-browsertests':
        ensure => directory,
        owner  => 'jenkins-deploy',
        group  => 'wikidev',
        mode   => '0775',
    }

    class { 'contint::browsertests':
        docroot => '/mnt/localhost-browsertests',
        require => File['/mnt/localhost-browsertests'],
    }

    # For CirrusSearch testing:
    file { '/mnt/elasticsearch':
        ensure => 'directory',
    }
    file { '/var/lib/elasticsearch':
        ensure  => 'link',
        require => File['/mnt/elasticsearch'],
        target  => '/mnt/elasticsearch',
    }
    class { '::elasticsearch':
        cluster_name => 'jenkins',
        heap_memory  => '1G', #We have small data in test
        require      => File['/var/lib/elasticsearch'],
        # We don't have reliable multicast in labs but we don't mind because we
        # only use a single instance

        # Right now we're not testing with any of the plugins we plan to install
        # later.  We'll cross that bridge when we come to it.
    }

    # For CirrusSearch testing:
    class { '::redis':
        maxmemory                 => '128mb',
        persist                   => 'aof',
        redis_replication         => undef,
        password                  => 'notsecure',
        dir                       => '/mnt/redis',
        auto_aof_rewrite_min_size => '32mb',
    }

}

class role::ci::slave::labs {

    system::role { 'role::ci::slave::labs':
        description => 'CI Jenkins slave on labs' }

    if $::realm != 'labs' {
        fail("role::ci::slave::labs must only be applied in labs")
    }

    class { 'role::ci::slave::browsertests':
        require => [
            Class['role::ci::slave::labs::common'],  # /mnt
            Class['contint::packages::labs'],  # realize common packages first
        ]
    }

    file { '/srv/localhost':
        ensure => directory,
        mode   => '0755',
        owner  => 'jenkins-deploy',
        group  => 'root',  # no jenkins-deploy group in labs
    }
    file { '/srv/localhost/mediawiki':
        ensure => directory,
        mode   => '0775',
        owner  => 'jenkins-deploy',
        group  => 'root',  # no jenkins-deploy group in labs
    }
    contint::localvhost { 'mediawiki':
        port       => 9414,
        docroot    => '/srv/localhost/mediawiki',
        log_prefix => 'mediawiki',
        require    => File['/srv/localhost/mediawiki'],
    }

    include role::ci::slave::labs::common,
        # Trebuchet replacement on labs
        contint::slave-scripts,
        # Include package unsafe for production
        contint::packages::labs

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
        path        => '/srv/doc',
        read_only   => 'no',
        require => [
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
