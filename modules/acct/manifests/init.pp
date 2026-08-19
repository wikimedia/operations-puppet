# SPDX-License-Identifier: Apache-2.0
# @summary Manages the process and login accounting system
# @param manage_logrotate Whether to provision a logrotate file for account logs
class acct (
  Boolean $manage_logrotate,
) {
  package { 'acct':
    ensure => installed,
  }

  if $manage_logrotate {
    logrotate::conf { 'pacct':
      source => 'puppet:///modules/acct/pacct.logrotate',
    }
  }
}
