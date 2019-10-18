# Class that installs the check script and all needed
# dependencies to run it, but does nothing else
class bacula::director::check {
    file { '/usr/local/sbin/check_bacula.py':
        ensure => present,
        mode   => '0500',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/bacula/check_bacula.py',
    }
}
