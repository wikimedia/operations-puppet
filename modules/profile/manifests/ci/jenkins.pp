# SPDX-License-Identifier: Apache-2.0
# [*jenkins_prefix*]
# The HTTP path used to reach the Jenkins instance. Must have a leading slash.
# Default: '/ci'.
#
class profile::ci::jenkins(
    Stdlib::Unixpath $prefix = lookup('profile::ci::jenkins::prefix'),
    Stdlib::Unixpath $builds_dir = lookup('profile::ci::jenkins::builds_dir'),
    Stdlib::Unixpath $workspaces_dir = lookup('profile::ci::jenkins::workspaces_dir'),
    Stdlib::Unixpath $java_home = lookup('profile::ci::jenkins::java_home'),
    Stdlib::Fqdn $zuul_scheduler_host = lookup('profile::ci::jenkins::zuul_scheduler_host'),
    Stdlib::Fqdn $jenkins_host = lookup('profile::ci::jenkins::jenkins_host'),
    Boolean $jenkins_enabled = lookup('profile::ci::jenkins::service_enabled'),
) {
    include profile::ci
    include ::profile::java
    Class['::profile::java'] ~> Class['::jenkins']
    include ::profile::ci::thirdparty_apt
    Class['::profile::ci::thirdparty_apt'] ~> Class['::jenkins']

    # Load the Jenkins module, that setup a Jenkins controller
    $service_enable = ($profile::ci::manager and $jenkins_enabled) ? {
        false   => 'mask',
        default => $profile::ci::manager,
    }

    $monitoring_enabled = $service_enable ? {
        mask    => false,
        default => true,
    }

    class { '::jenkins':
        http_port          => 8080,
        prefix             => $prefix,
        umask              => '0002',
        service_ensure     => stdlib::ensure($profile::ci::manager, 'service'),
        service_enable     => $service_enable,
        service_monitor    => $profile::ci::manager,
        builds_dir         => $builds_dir,
        workspaces_dir     => $workspaces_dir,
        java_home          => $java_home,
        monitoring_enabled => $monitoring_enabled,
    }

    # Templates for Jenkins plugin Email-ext.
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

    $jenkins_build_monitor_script = '/usr/local/bin/prometheus-jenkins-build-monitor'
    $jenkins_build_monitor_outfile = '/var/lib/prometheus/node.d/jenkins_build_monitor.prom'

    prometheus::node_textfile { 'prometheus-jenkins-build-monitor':
        ensure     => stdlib::ensure($profile::ci::manager),
        filesource => 'puppet:///modules/profile/ci/prometheus-jenkins-build-monitor.py',
        interval   => 'minutely',
        run_cmd    => join([
            $jenkins_build_monitor_script,
            "--outfile ${jenkins_build_monitor_outfile}",
        ], ' '),
        user       => 'root',
    }

    if !$profile::ci::manager {
        file { $jenkins_build_monitor_outfile:
            ensure => absent,
        }
    }

    # allow syncing jenkins data between servers for migration
    # but do not automatically do it
    rsync::quickdatacopy { 'var-lib-jenkins-contint':
      ensure              => present,
      auto_sync           => false,
      server_uses_stunnel => true,
      delete              => true,
      source_host         => $zuul_scheduler_host,
      dest_host           => $jenkins_host,
      module_path         => '/var/lib/jenkins',
    }

    # Allow zuul-merger contint machines to talk to
    # jenkins, behind envoy, on new jenkins machines.
    firewall::service { 'jenkins-contint':
        proto  => 'tcp',
        port   => 1443,
        srange => [$zuul_scheduler_host],
    }

    # Ensure firewall rule is applied before trying to start jenkins.
    Firewall::Service['jenkins-contint'] -> Service['jenkins']
}
