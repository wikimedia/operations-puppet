# vim: set et ts=4 sw=4:

# role::ci::master
#
# Setup a Jenkins installation attended to be used as a master. This setup some
# CI specific requirements such as having workspace on a SSD device and Jenkins
# monitoring.
#
# CI test server as per T79623
#
# [*jenkins_prefix*]
# The HTTP path used to reach the Jenkins instance. Must have a leading slash.
# Default: '/ci'.
#
# filtertags: labs-project-ci-staging
class role::ci::master(
    $jenkins_prefix = '/ci'
) {

    system::role { 'role::ci::master': description => 'CI Jenkins master' }

    # We require the CI website to be on the same box as the master
    # as of July 2013.  So make sure the website has been included on the node.
    require role::ci::website

    # Load the Jenkins module, that setup a Jenkins master
    class { '::jenkins':
        access_log => true,
        http_port  => '8080',
        prefix     => $jenkins_prefix,
        umask      => '0002',
    }
    class { '::contint::proxy_jenkins':
        http_port => '8080',
        prefix    => $jenkins_prefix,
    }

    # Backups
    include ::role::backup::host
    backup::set {'var-lib-jenkins-config': }
    backup::set { 'contint' : }

    # Nodepool spawn non ephemeral slaves which causes config-history plugin to
    # fill up entries until it reaches the limit of 32k inodes. T126552
    cron { 'tidy_jenkins_ephemeral_nodes_configs':
        ensure      => present,
        environment => 'MAILTO=jenkins-bot@wikimedia.org',
        user        => 'jenkins',
        command     => "/usr/bin/find /var/lib/jenkins/config-history/nodes -path '/var/lib/jenkins/config-history/nodes/ci-*' -mmin +60 -delete > /dev/null 2>&1",
        minute      => '35',
        hour        => '*',
    }

    nrpe::monitor_service { 'jenkins_zmq_publisher':
        description   => 'jenkins_zmq_publisher',
        contact_group => 'contint',
        nrpe_command  => '/usr/lib/nagios/plugins/check_tcp -H 127.0.0.1 -p 8888 --timeout=2',
    }


    # Templates for Jenkins plugin Email-ext.  The templates are hosted in
    # the repository integration/jenkins.git, so link to there.
    file { '/var/lib/jenkins/email-templates':
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }
    file { '/var/lib/jenkins/email-templates/wikimedia.template':
        source  => 'puppet:///modules/contint/jenkins-email-template',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        require => File['/var/lib/jenkins/email-templates'],
    }

}
