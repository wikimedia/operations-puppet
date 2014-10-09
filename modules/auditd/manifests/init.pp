# == Class: auditd
#
# This Puppet module installs and manages auditd, the Linux Audit Daemon.
# It provides a custom resource type, 'auditd::rules', which can be used
# to provision an auditd rules file.
#
class auditd {
    package { 'auditd':
        ensure => present,
    }

    service { 'auditd':
        ensure   => running,
        enable   => true,
        provider => 'debian',
        require  => Package['auditd'],
    }

    file { '/etc/audit/rules.d':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0750',
        recurse => true,
        purge   => true,
        force   => true,
        ignore  => 'audit.rules',
        require => Package['auditd'],
        notify  => Service['auditd'],
    }
}
