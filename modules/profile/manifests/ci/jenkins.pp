# [*jenkins_prefix*]
# The HTTP path used to reach the Jenkins instance. Must have a leading slash.
# Default: '/ci'.
#
class profile::ci::jenkins(
    $prefix = hiera('profile::ci::jenkins::prefix'),
    $service_ensure = hiera('profile::ci::jenkins::service_ensure'),
    $service_enable = hiera('profile::ci::jenkins::service_enable'),
    $service_monitor = hiera('profile::ci::jenkins::monitor'),
) {
    # Load the Jenkins module, that setup a Jenkins master
    class { '::jenkins':
        access_log      => true,
        http_port       => '8080',
        prefix          => $prefix,
        umask           => '0002',
        service_ensure  => $service_ensure,
        service_enable  => $service_enable,
        service_monitor => $service_monitor,
    }
    # Nodepool spawns non ephemeral slaves which causes config-history plugin
    # to fill up entries until it reaches the limit of 32k inodes. T126552
    cron { 'tidy_jenkins_ephemeral_nodes_configs':
        ensure      => present,
        environment => 'MAILTO=jenkins-bot@wikimedia.org',
        user        => 'jenkins',
        command     => "/usr/bin/find /var/lib/jenkins/config-history/nodes -path '/var/lib/jenkins/config-history/nodes/ci-*' -mmin +60 -delete > /dev/null 2>&1",
        minute      => '35',
        hour        => '*',
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

    # TODO/FIXME: remove hiera condition once T150771 is resolved
    # and jenkins service is running active/active in both DCs
    # aware that there should not be permanent hiera lookups in role
    # should also be converted to profile/role anyways (T162822)
    if $service_monitor {
        nrpe::monitor_service { 'jenkins_zmq_publisher':
            description   => 'jenkins_zmq_publisher',
            contact_group => 'contint',
            nrpe_command  => '/usr/lib/nagios/plugins/check_tcp -H 127.0.0.1 -p 8888 --timeout=2',
        }
    }
}
