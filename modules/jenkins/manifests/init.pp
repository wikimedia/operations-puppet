# == Class jenkins
#
# Set up a basic Jenkins master instance for CI.
#
# == Parameters:
#
# [*service_ensure*]
#
# Passed to Puppet Service['jenkins']. If set to 'unmanaged', pass undef to
# prevent Puppet from managing the service. Default: 'running'.
#
# [*service_enable*]
#
# Passed to Puppet Service['jenkins'] as 'enable'. Default: true.
#
class jenkins(
    $service_ensure  = 'running',
    $service_enable = true,
)
{
    user { 'jenkins':
        home       => '/var/lib/jenkins',
        shell      => '/bin/bash',  # admins need to be able to login
        gid        => 'jenkins',
        system     => true,
        managehome => false,
        require    => Group['jenkins'],
    }

    group { 'jenkins':
        ensure    => present,
        name      => 'jenkins',
        system    => true,
        allowdupe => false,
    }

    # We want to run Jenkins under Java 7.
    ensure_packages(['openjdk-7-jre-headless'])

    alternatives::select { 'java':
        path    => '/usr/lib/jvm/java-7-openjdk-amd64/jre/bin/java',
        require => Package['openjdk-7-jre-headless'],
    }

    # Upgrades are usually done manually by upload the Jenkins
    # package at apt.wikimedia.org then restarting jenkins and
    # double checking everything went fine.
    package { 'jenkins':
        ensure  => present,
        require => Package['openjdk-7-jre-headless'],
    }


    # Jenkins should write everything group writable so admins can interact with
    # files easily, hence we need it to run with umask 0002.
    # The Jenkins software is daemonized in the init script using
    # /usr/bin/daemon which reset the umask value.  Daemon accepts per user
    # configuration via the ~/.daemonrc, set the umask there.
    file { '/var/lib/jenkins/.daemonrc':
        ensure  => 'present',
        content => "jenkins umask=0002\n",
        owner   => 'jenkins',
        group   => 'jenkins',
        mode    => '0644',
    }

    # Workaround for a Jenkins security issue.
    #
    # Same fix as a previous one:
    #   https://jenkins.io/blog/2015/11/06/mitigating-unauthenticated-remote-code-execution-0-day-in-jenkins-cli/
    #   https://github.com/jenkinsci-cert/SECURITY-218
    file { '/var/lib/jenkins/init.groovy.d':
        ensure => directory,
        owner  => 'jenkins',
        group  => 'jenkins',
        mode   => '0755',
    }
    file { '/var/lib/jenkins/init.groovy.d/cli-shutdown.groovy':
        source => 'puppet:///modules/jenkins/cli-shutdown.groovy',
        owner  => 'jenkins',
        group  => 'jenkins',
        mode   => '0755',
    }

    $real_ensure = $service_ensure ? {
        'unmanaged' => undef,
        default     => $service_ensure,
    }
    service { 'jenkins':
        ensure     => $real_ensure,
        enable     => $service_enable,
        hasrestart => true,
        # Better have umask properly set before starting
        require    => File['/var/lib/jenkins/.daemonrc'],
    }

    # nagios monitoring
    nrpe::monitor_service { 'jenkins':
        description   => 'jenkins_service_running',
        contact_group => 'contint',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 --ereg-argument-array '^/usr/bin/java .*-jar /usr/share/jenkins/jenkins.war'",
    }

    file { '/var/lib/jenkins':
        ensure => directory,
        mode   => '2775',  # group sticky bit
        owner  => 'jenkins',
        group  => 'jenkins',
    }
    # Top level jobs folder
    file { '/var/lib/jenkins/jobs':
        ensure => directory,
        mode   => '2775',  # group sticky bit
        owner  => 'jenkins',
        group  => 'jenkins',
    }

    file { '/etc/logrotate.d/jenkins':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/jenkins/jenkins_log.logrotate',
        require => Package['jenkins'],
    }

    file { '/etc/default/jenkins':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/jenkins/etc_default_jenkins',
        require => Package['openjdk-7-jre-headless'],
    }

}
