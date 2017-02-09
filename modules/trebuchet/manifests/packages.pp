# == Class: trebuchet::packages
#
# Provision packages required for trebuchet to operate
#
class trebuchet::packages {
    include ::redis::client::python

    if !defined(Package['git-fat'] {
        package { 'git-fat':
            ensure => '0.1.2',
        }
    }
}
