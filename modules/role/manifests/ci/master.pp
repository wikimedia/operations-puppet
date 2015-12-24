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

    nrpe::monitor_service { 'jenkins_zmq_publisher':
        description   => 'jenkins_zmq_publisher',
        contact_group => 'contint',
        nrpe_command  => '/usr/lib/nagios/plugins/check_tcp -H 127.0.0.1 -p 8888 --timeout=2',
    }


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

