# == Class: trebuchet::packages
#
# Provision packages required for trebuchet to operate
#
class trebuchet::packages {
    include ::redis::client::python

    if os_version('ubuntu > lucid') {
        package { 'git-fat':
            ensure => present,
        }
    }
}
