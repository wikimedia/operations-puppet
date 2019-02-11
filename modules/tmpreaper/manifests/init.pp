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

    # We modify the original file shipped with debian for the following reasons:
    # - we remove SHOWWARNING=true so that tmpreaper actually runs
    # - we add an additional protect rule so that tmpreaper plays nice with
    #   systemd's private temporary directories

    file { '/etc/tmpreaper.conf':
      ensure => present,
      source => 'puppet:///modules/tmpreaper/tmpreaper.conf'
    }
}
