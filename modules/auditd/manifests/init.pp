# SPDX-License-Identifier: Apache-2.0
# == Class: auditd
#
# Installs and configures auditd: the Linux audit daemon. This is only intended
# to be used on the doh* hosts, for the Wikidough project.
#
# == Parameters:
#
#  [*log_to_disk*]
#    [bool] whether to log audit logs to disk. default: true.
#
#  [*log_file*]
#    [path] path to the log file, if log_to_disk is true. default: /var/log/audit/audit.log.
#
#  [*rule_root_cmds*]
#    [bool] whether to append the rule to log all root commands. default: false.
#
#  [*send_to_syslog*]
#    [bool] whether to dispatch auditd events to syslog using audispd. default: false.

class auditd (
    Boolean          $log_to_disk    = true,
    Stdlib::Unixpath $log_file       = '/var/log/audit/audit.log',
    Boolean          $rule_root_cmds = false,
    Boolean          $send_to_syslog = false,
) {

    ensure_packages(['auditd'])

    file {
        default:
            ensure  => 'file',
            require => Package['auditd'],
            owner   => 'root',
            group   => 'root',
            mode    => '0440',
            notify  => Service['auditd'];
        '/etc/audit/auditd.conf':
            content => template('auditd/auditd.conf.erb');
        '/etc/audit/rules.d/audit.rules':
            content => template('auditd/audit.rules.erb');
        '/etc/audisp/plugins.d/syslog.conf':
            content => template('auditd/audisp-syslog.conf.erb');
    }

    service { 'auditd':
        ensure     => 'running',
        enable     => true,
        hasrestart => true,
    }

    profile::auto_restarts::service { 'auditd': }
}
