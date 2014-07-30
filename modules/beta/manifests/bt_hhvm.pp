# == Class: beta::bt_hhvm
#
# Provision the bt-hhvm script which can be used to collect a backtrace and
# core file for a running hhvm process.
#
class beta::bt_hhvm {
    file { '/usr/local/bin/bt-hhvm':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/beta/bt-hhvm',
    }
}
