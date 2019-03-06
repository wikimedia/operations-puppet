# == Class: base::restarts
#
# This class automates service restarts for stateless services after
# a library upgrade
#
class base::auto_restarts
{
    file { '/usr/local/sbin/wmf-auto-restart':
        ensure => present,
        source => 'puppet:///modules/base/wmf-auto-restart.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/etc/debdeploy-client/autorestarts.conf':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
    }
}
