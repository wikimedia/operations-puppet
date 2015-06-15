# == Class: tmpreaper
#
# This module provides a simple custom resource type for using
# tmpreaper. tmpreaper recursively searches for and removes files
# and empty directories which haven't been accessed for a period
# time.
#
class tmpreaper {
    package { 'tmpreaper':
        ensure => present,
    }

    # tmpreaper's cron.daily script declines to run unless the line
    # below is removed from its config file, indicating that the user
    # understands the security implications of having tmpreaper run
    # automatically. See /usr/share/doc/tmpreaper/README.security.gz .

    file_line { 'enable_tmpreaper':
        ensure  => absent,
        line    => 'SHOWWARNING=true',
        path    => '/etc/tmpreaper.conf',
        require => Package['tmpreaper'],
    }
}
