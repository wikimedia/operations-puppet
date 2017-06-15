# == Class jenkins
#
# Set up a basic Jenkins master instance for CI.
#
# == Parameters:
#
# [*prefix*]
# Prefix for web access to use with Apache proxying. Must be the full path with
# a leading slash. Example: /ci
#
# [*access_log*]
# Whether to enable the web service access.log. Boolean. Default: false
#
# [*log_group*]
# Unix group for the log files under /var/log/jenkins. Default: 'wikidev'
#
# [*http_port*]
# HTTP port for the web service. Default: 8080
#
# [*max_open_files*]
# Maximum number of file descriptors. Passed to systemd LimitNOFILE.
# Default: 8192.
#
# [*service_ensure*]
# Passed to Puppet Service['jenkins']. If set to 'unmanaged', pass undef to
# prevent Puppet from managing the service. Default: 'running'.
#
# [*service_enable*]
# Passed to Puppet Service['jenkins'] as 'enable'. Default: true.
#
# [*umask*]
# Control permission bits of files created by Jenkins. Passed to systemd.
# Default: '0002'
class jenkins(
    $prefix,
    $access_log = false,
    $log_group = 'wikidev',
    $http_port = '8080',
    $max_open_files = '8192',
    $service_ensure  = 'running',
    $service_enable = true,
    $umask = '0002'
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
    # (unless when we are on stretch and there is no Java 7 anymore)
    if os_version('debian >= stretch') {
        $jdk_version = '8'
    } else {
        $jdk_version = '7'
    }
    $jdk_package = "openjdk-${jdk_version}-jdk"
    ensure_packages($jdk_package)

    # Upgrades are usually done manually by upload the Jenkins
    # package at apt.wikimedia.org then restarting jenkins and
    # double checking everything went fine.
    package { 'jenkins':
        ensure  => present,
        require => Package['openjdk-7-jdk'],
    }

    file { '/var/lib/jenkins/.daemonrc':
        ensure  => 'absent',
    }

    file { '/etc/jenkins':
        ensure => directory,
        owner  => 'jenkins',
        group  => 'jenkins',
        mode   => '0755',
    }
    file { '/etc/jenkins/logging.properties':
        content => template('jenkins/logging.properties.erb'),
        owner   => 'jenkins',
        group   => 'jenkins',
        mode    => '0755',
    }

    systemd::syslog { 'jenkins':
        base_dir     => '/var/log',
        owner        => 'jenkins',
        group        => $log_group,
        readable_by  => 'group',
        log_filename => 'jenkins.log',
    }

    if $access_log {
        $jenkins_access_log_arg = '--accessLoggerClassName=winstone.accesslog.SimpleAccessLogger --simpleAccessLogger.format=combined --simpleAccessLogger.file=/var/log/jenkins/access.log'
        file { '/var/log/jenkins/access.log':
            ensure  => present,
            replace => false,
            owner   => 'jenkins',
            group   => $log_group,
            mode    => '0640',
            before  => Service['jenkins'],
        }
    } else {
        $jenkins_access_log_arg = ''
    }

    $java_args = join([
        # Allow graphs etc. to work even when an X server is present
        '-Djava.awt.headless=true',
        # Make Git plugin verbose which dramatically helps debugging
        '-Dhudson.plugins.git.GitSCM.verbose=true',
        # Prevents Jenkins 1.651.2+ from stripping parameters injected by the
        # Gearman plugin.
        #
        # References:
        #   https://phabricator.wikimedia.org/T133737
        #   https://jenkins.io/blog/2016/05/11/security-update/
        #   https://wiki.jenkins-ci.org/display/SECURITY/Jenkins+Security+Advisory+2016-05-11
        '-Dhudson.model.ParametersAction.keepUndefinedParameters=true',
        '-Djava.util.logging.config.file=/etc/jenkins/logging.properties',
    ], ' ')

    $real_service_ensure = $service_ensure ? {
        'unmanaged' => undef,
        # Normalize to 'running' or 'stopped'
        default     => ensure_service($service_ensure),
    }

    base::service_unit { 'jenkins':
        ensure         => 'present',
        sysvinit       => false,
        systemd        => true,
        refresh        => false,
        service_params => {
            enable => $service_enable,
            ensure => $real_service_ensure,
        },
        require        => [
            Systemd::Syslog['jenkins'],
            File['/etc/default/jenkins'],
        ],
    }

    # TODO/FIXME: remove hiera condition once T150771 is resolved
    # and jenkins service is running active/active in both DCs 
    # aware that there should not be permanent hiera lookups here
    # should also be converted to profile/role anyways (T162822)
    if hiera('jenkins::service_monitor', true) {
        nrpe::monitor_service { 'jenkins':
            description   => 'jenkins_service_running',
            contact_group => 'contint',
            nrpe_command  => "/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 --ereg-argument-array '^/usr/bin/java .*-jar /usr/share/jenkins/jenkins.war'",
        }
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

    file { '/etc/default/jenkins':
        ensure  => absent,
        require => Package['jenkins'],
    }

}
