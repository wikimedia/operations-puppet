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
}
