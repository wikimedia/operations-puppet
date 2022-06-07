# SPDX-License-Identifier: Apache-2.0
# == Class: kerberos::wrapper
#
# Deploy a simple kerberos wrapper to kinit before running
# a command.
#
# == Parameters
#
# [*skip_wrapper*]
#   This variable is convenient when testing Hadoop in a non-kerberized
#   environment (like cloud), since kerberos::exec and kerberos::systemd::timers can
#   have a single place to check to decide if to run without trying to authenticate
#   to kerberos first or not.
#   Default: false
#
class kerberos::wrapper (
    Boolean $skip_wrapper = false,
){

    $kerberos_run_command_script = '/usr/local/bin/kerberos-run-command'

    file { $kerberos_run_command_script:
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/kerberos/kerberos_run_command.py',
    }
}