# == Class: trebuchet::packages
#
# Provision packages required for trebuchet to operate
#
class trebuchet::packages {
    include ::redis::client::python

    if ubuntu_version('> lucid') {
        package { 'git-fat':
            ensure => present,
        }
    }
}
