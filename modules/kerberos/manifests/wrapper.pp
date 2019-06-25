# == Class: kerberos::wrapper
#
# Deploy a simple kerberos wrapper to kinit before running
# a command.
#
class kerberos::wrapper {

    $kerberos_run_command_script = '/usr/local/bin/kerberos-run-command'

    file { $kerberos_run_command_script:
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/kerberos/kerberos_run_command.py',
    }
}