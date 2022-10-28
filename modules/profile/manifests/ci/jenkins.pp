# SPDX-License-Identifier: Apache-2.0
# [*jenkins_prefix*]
# The HTTP path used to reach the Jenkins instance. Must have a leading slash.
# Default: '/ci'.
#
class profile::ci::jenkins(
    Stdlib::Unixpath $prefix = lookup('profile::ci::jenkins::prefix'),
    Variant[Enum['running', 'stopped'], Boolean] $service_ensure = lookup('profile::ci::jenkins::service_ensure'),
    Variant[Enum['mask', 'manual'], Boolean] $service_enable = lookup('profile::ci::jenkins::service_enable'),
    Boolean $service_monitor = lookup('profile::ci::jenkins::service_monitor'),
    Stdlib::Unixpath $builds_dir = lookup('profile::ci::jenkins::builds_dir'),
    Stdlib::Unixpath $workspaces_dir = lookup('profile::ci::jenkins::workspaces_dir'),
    Stdlib::Unixpath $java_home = lookup('profile::ci::jenkins::java_home'),
) {
    include ::profile::java
    Class['::profile::java'] ~> Class['::jenkins']

    # Load the Jenkins module, that setup a Jenkins master
    class { '::jenkins':
        access_log      => true,
        http_port       => 8080,
        prefix          => $prefix,
        umask           => '0002',
        service_ensure  => $service_ensure,
        service_enable  => $service_enable,
        service_monitor => $service_monitor,
        builds_dir      => $builds_dir,
        workspaces_dir  => $workspaces_dir,
        java_home       => $java_home,
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
}
