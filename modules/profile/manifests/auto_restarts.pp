# == Class: profile::auto_restarts
#
# This class automates service restarts for stateless services after
# a library upgrade.
#
class profile::auto_restarts(
    Boolean $with_debdeploy = lookup('profile::auto_restarts::with_debdeploy'),
) {
    file { '/usr/local/sbin/wmf-auto-restart':
        ensure => present,
        source => 'puppet:///modules/base/wmf-auto-restart.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}
